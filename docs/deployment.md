# End-to-End Deployment

This guide deploys the development slice and runs a real drift investigation. Review region
availability, quota, access, and cost before applying.

## 1. Prerequisites

- Azure subscription permission to create the listed resources, assign runtime roles, and configure
  subscription Activity Log diagnostics.
- Azure CLI, Terraform 1.9 or later, Python 3.12 or later, Git, Azure Functions Core Tools 4, and
  Microsoft Foundry portal access to deploy a model.
- A Foundry-supported region and available model deployment. Search SKU and model capacity affect
  cost; validate them before provisioning.
- For GitHub Actions, an Entra application/service principal with a federated credential for this
  repository and the `dev` GitHub environment.

## 2. Sign In and Configure Names

From the repository root in PowerShell:

```powershell
az login
az account set --subscription <subscription-id>
Copy-Item environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Edit `environments/dev/terraform.tfvars`: set your subscription ID and a unique lowercase
`name_suffix` (4-8 letters/digits). Confirm the selected region supports Foundry and your model.

## 3. Bootstrap the Remote State Backend

Terraform needs a backend before it can initialize. The state bootstrap script creates a separate
resource group, Storage account, and private container:

```powershell
$subscriptionId = "<subscription-id>"
$suffix = "<unique-suffix>"
.\scripts\bootstrap-state.ps1 -SubscriptionId $subscriptionId -NameSuffix $suffix -Location eastus2
```

The signed-in identity needs `Storage Blob Data Contributor` on the state account to create the
container and run Terraform. If container creation is denied, have an administrator assign that
data-plane role, wait for RBAC propagation, and rerun the script.

Initialize with Entra authentication:

```powershell
terraform -chdir=environments/dev init `
  -backend-config="resource_group_name=rg-tdip-state-$suffix" `
  -backend-config="storage_account_name=sttdipstate$suffix" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=terraform-drift/dev.tfstate" `
  -backend-config="use_azuread_auth=true"
```

## 4. Validate and Provision

```powershell
terraform fmt -recursive
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev plan
```

Review the plan, then deploy:

```powershell
terraform -chdir=environments/dev apply
```

Terraform creates the resource group, Function App and host Storage, Log Analytics and Application
Insights, Microsoft Foundry resource/project, Azure AI Search, runtime role assignments, and
subscription Activity Log diagnostic settings. The applying identity must be allowed to create role
assignments and subscription-level diagnostic settings.

## 5. Deploy a Model and Create the Foundry Agent

In Microsoft Foundry, open the project endpoint from Terraform output and deploy a supported chat
model. Note its deployment name; availability and quota depend on the region and subscription.

From the repository root, create and activate a local Python environment and install the agent
script's dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install "azure-ai-projects>=2.3.0" "azure-identity>=1.19.0"
```

With that environment active, set the endpoint, agent name, and actual model deployment name,
then create a versioned prompt agent:

```powershell
$env:FOUNDRY_PROJECT_ENDPOINT = terraform -chdir=environments/dev output -raw foundry_project_endpoint
$env:FOUNDRY_AGENT_NAME = "terraform-drift-investigator"
$env:FOUNDRY_MODEL_DEPLOYMENT = "<model-deployment-name>"
python scripts/create_foundry_agent.py
```

The prompt is versioned at `src/agents/recommendation-agent/prompt.txt`. Re-running the script
creates another agent version; review it in Foundry before promotion.

## 6. Create and Populate Azure AI Search

Grant the indexing identity `Search Service Contributor` and `Search Index Data Contributor` on the
Search service. Put approved, non-secret `.md` or `.txt` material under `knowledge/`, then run:

```powershell
$env:AI_SEARCH_ENDPOINT = terraform -chdir=environments/dev output -raw ai_search_endpoint
$env:AI_SEARCH_INDEX = "platform-knowledge"
python scripts/index_documents.py
```

The index stores source paths and full-text content. It does not generate embeddings or enable
vector/agentic retrieval. The Function identity has read-only index access.

## 7. Publish the Function App

Install Azure Functions Core Tools 4 and use Python 3.12. From the repository root:

```powershell
$functionApp = terraform -chdir=environments/dev output -raw function_app_name
Push-Location src/function-app
func azure functionapp publish $functionApp --python
Pop-Location
```

The Function uses its system-assigned managed identity for Foundry, Search, and Log Analytics. Allow
time for RBAC propagation before the first invocation.

## 8. Configure GitHub Actions OIDC

Create an Entra federated credential for this repository and GitHub environment `dev`. Grant the
workflow identity minimum permissions for Terraform state, platform resources, role assignments, and
subscription diagnostics. Configure these `dev` environment variables:

| Variable | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | Federated application/client ID |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `TF_NAME_SUFFIX` | Same globally unique suffix as `environments/dev/terraform.tfvars` |
| `TFSTATE_RESOURCE_GROUP` | `rg-tdip-state-<suffix>` |
| `TFSTATE_STORAGE_ACCOUNT` | `sttdipstate<suffix>` |
| `DRIFT_FUNCTION_URL` | Terraform output `function_app_url` |

Add `DRIFT_FUNCTION_KEY` as a GitHub environment secret. Retrieve the Function key without
committing it:

```powershell
$resourceGroup = terraform -chdir=environments/dev output -raw resource_group_name
$functionApp = terraform -chdir=environments/dev output -raw function_app_name
$functionKey = az functionapp keys list --resource-group $resourceGroup --name $functionApp --query "functionKeys.default" --output tsv
gh secret set DRIFT_FUNCTION_KEY --env dev --body $functionKey
Remove-Variable functionKey
```

Workflows validate Terraform on pull requests, provide a manual apply workflow, and run drift
investigation every four hours or on demand.

## 9. Test the Analyzer and Endpoint

Run the dependency-free unit tests:

```powershell
python -m unittest discover -s tests -v
```

For a deployed HTTP smoke test, post the sample plan with the Function key in the request header:

```powershell
$url = terraform -chdir=environments/dev output -raw function_app_url
$resourceGroup = terraform -chdir=environments/dev output -raw resource_group_name
$functionApp = terraform -chdir=environments/dev output -raw function_app_name
$key = az functionapp keys list --resource-group $resourceGroup --name $functionApp --query "functionKeys.default" --output tsv
curl.exe --fail-with-body --silent --show-error -X POST $url `
  -H "Content-Type: application/json" `
  -H "x-functions-key: $key" `
  --data-binary "@samples/refresh-drift-plan.json"
Remove-Variable key
```

Expected: HTTP 200, `drift_count` is `1`, and `tags.environment` is reported. Search evidence may be
empty until documents are indexed; a Foundry recommendation appears after the agent is created and
role assignments propagate. Sensitive plan values must be `[REDACTED]`.

## 10. Exercise Real Drift

Change the development Resource Group's `environment` tag outside Terraform, then run the
`Terraform Drift Investigation` workflow manually:

```powershell
$resourceGroup = terraform -chdir=environments/dev output -raw resource_group_name
az group update --name $resourceGroup --set tags.environment=manual-test
```

Confirm the report names the Resource Group and tag difference. Restore the configured value with:

```powershell
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

Do not run `terraform apply -refresh-only` for this test; that would accept the out-of-band value
into state rather than restoring the configured tag.

## 11. Local Development and Cleanup

Install dependencies with `scripts/bootstrap.ps1`, copy `local.settings.example.json` to
`src/function-app/local.settings.json`, and use Azurite for local Functions host storage. Local
Foundry and Search calls require Azure CLI sign-in and their corresponding RBAC roles.

To remove the platform, run `terraform -chdir=environments/dev destroy` first. Keep the separate
state Storage account until the platform state is no longer needed; delete it deliberately as the
last step. Verify no shared resources or diagnostics are owned by other workloads.