# Terraform Drift Platform: Manual Setup from Scratch

Follow this guide **in order** to create resources in Azure portal, assign access, configure
Foundry/Search, deploy the Function, configure drift detection, and finally test everything.
No Terraform infrastructure deployment is needed. If a resource already exists, verify and reuse
it instead of creating a duplicate.

**Scope:** This matches the current repository implementation, not the broader historical diagrams.
The instructions have been checked against the source code; your Azure deployment has not been
validated by this document.

## Setup sequence

| Phase | Work | Complete before continuing |
| --- | --- | --- |
| 1 | Prerequisites and naming | Subscription, permissions, regions, and tools ready. |
| 2 | Create all Azure resources | Function, Storage, monitoring, Foundry project, Search, and OIDC application exist. |
| 3 | Configure identities, RBAC, networking, and diagnostics | Runtime, operator, and workflow permissions assigned. |
| 4 | Prepare local tools and sign in | Python environment and SDKs installed. |
| 5 | Deploy Foundry model and create the agent | Versioned prompt agent references a ready chat deployment. |
| 6 | Create Search index and upload knowledge | Approved documents uploaded with the expected schema. |
| 7 | Configure and publish the Function | Application settings saved and `investigate` discovered. |
| 8 | Configure Terraform tracking and GitHub | Real tracked resource/state and scheduled workflow ready. |
| 9 | Test the completed deployment | Service checks, HTTP test, real drift, and schedule pass. |
| 10 | Operate and maintain | Retain sanitized sign-off evidence and ownership. |

### What you are building

```text
GitHub Actions -> Terraform refresh-only plan -> HTTP Azure Function
                                                |-> Log Analytics: activity evidence
                                                |-> AI Search: approved knowledge
                                                |-> Foundry prompt agent: recommendation
                                                \-> JSON investigation report
```

The Function calls **one** Foundry prompt agent. Folders under [src/agents](../src/agents)
are helpers, not separately deployed Foundry agents. The active entry point is
[function_app.py](../src/function-app/function_app.py), which calls the parser and service clients
directly. It retrieves up to three Search results per drift and supplies them to Foundry.

You do **not** need a Foundry-to-Search tool connection, embeddings, vector search, semantic
ranking, a Search indexer, or a separate Azure OpenAI resource. PIM/Graph verification,
Teams/GitHub notifications, durable queues, and investigation history are not wired into this flow.
Creating Service Bus, Cosmos DB, Key Vault, API Management, or a container registry will not enable
those features. Key Vault and private networking may still be required by your organization's policy.

## 1. Prepare access, tools, and names

1. Choose an Azure tenant/subscription and approved regions. Check Foundry model availability,
   quota, and Function hosting availability before creation.
2. Obtain resource-creation permissions, role-assignment permissions such as **Role Based Access
   Control Administrator**, subscription diagnostic-setting permissions, and permission to create
   an Entra app registration. One role does not necessarily grant all of these.
3. Install **Python 3.12**, a current **Azure CLI** supporting Flex ZIP deployment and remote build,
   **Terraform 1.9 or later**, and Git. Core Tools (`func`) is not required for this deployment
   method. Check the repository's provider constraints.
4. Have GitHub repository/environment administration access for the scheduled workflow.
5. Review costs: Search tier, model capacity/tokens, Function hosting, Storage, and log ingestion.

Use a short unique suffix below. Storage names must be globally unique, 3-24 lowercase letters/digits.
Names are examples, not mandatory values.

| Resource | Example name | Purpose |
| --- | --- | --- |
| Platform resource group | `rg-tdip-platform-dev` | Application resources. |
| Log Analytics | `law-tdip-dev` | Activity evidence and telemetry workspace. |
| Application Insights | `appi-tdip-dev` | Function monitoring. |
| Function host Storage | `sttdipapp<suffix>` | Function host/deployment storage, not Terraform state. |
| Function App and hosting plan | `func-tdip-<suffix>` | Python HTTP endpoint. |
| Foundry resource / project | `fdry-tdip-<suffix>` / `drift-investigation` | Model and prompt agent. |
| AI Search | `srch-tdip-<suffix>` | Knowledge retrieval. |
| State resource group / Storage | `rg-tdip-state-dev` / `sttdipstate<suffix>` | Separate protected Terraform backend. |
| State Blob container | `tfstate` | Private container; state key configured later. |
| Entra app registration | `tdip-drift-reader` | GitHub OIDC sign-in. |
| Test resource group | `rg-tdip-drift-test` | Harmless resource for the first real drift test. |

Record names, resource IDs, and regions in an approved operational record. Never record keys,
tokens, connection strings, or Terraform state in this guide.

## 2. Create all Azure resources in the portal

Use [Azure portal](https://portal.azure.com). Do not run the repository bootstrap/apply scripts
for this manual route. Foundry project creation uses the linked
[Foundry portal](https://ai.azure.com); menu names can vary.

### 2.1 Resource groups and monitoring

1. **Resource groups -> Create**: create the platform, state, and test groups from section 1.
   Use the selected subscription and approved region.
2. **Log Analytics workspaces -> Create**: select the platform group and create the workspace.
   Record its **Workspace ID GUID** from Overview/Properties, not its ARM resource ID.
3. **Application Insights -> Create**: select the platform group and the existing workspace.
   Do not unintentionally create a second workspace. Record where to retrieve its connection
   string securely when configuring the Function.
4. On the test group's **Tags** page, set `environment=dev`. Leave other tags intact.
   This group will be tracked by Terraform later without Terraform creating it.

### 2.2 Function host Storage

1. **Storage accounts -> Create**: select the platform group, unique account name, Standard
   performance, **StorageV2/general purpose v2**, and LRS for a development environment.
2. Require HTTPS/TLS 1.2 or later and disable anonymous Blob access.
3. Select network access compatible with your Function hosting/network design.
4. Create the account. Let the Function wizard configure its host/deployment storage.

For the simplest development route, keep the wizard's supported connection-string authentication
if organizational policy permits it. The repository's Terraform uses key-based host Storage.
If Shared Key is prohibited, use the Functions identity-based Storage configuration and complete
the conditional roles in section 3 before publishing. Do not disable Shared Key while leaving
the Function configured to use an account key.

### 2.3 Function App and plan

1. **Create a resource -> Function App**: choose **Flex Consumption** for a new Linux serverless
   app where supported. Choose Python **3.12**, Functions runtime **4**, and code deployment.
   An approved Linux Premium plan is an alternative when networking/capacity requires it.
2. Select the platform group, approved region, unique Function name, and host Storage account.
   Review instance size/scale costs and any deployment-storage resources created by the wizard.
3. Enable monitoring and select the Application Insights component from section 2.1.
4. Keep HTTPS enabled. Retain Function-key HTTP authentication for this repository's caller;
   enabling App Service Authentication would require corresponding caller changes.
5. Review and create. Verify the Function and hosting plan provision successfully.
6. **Function App -> Identity -> System assigned -> On -> Save**. Record its principal/object ID.

Do not publish code yet. An empty Function App will not list `investigate` until phase 7.
The Terraform module declares legacy Linux Consumption/Y1, but this manual route can use Flex.
Do not copy classic `WEBSITE_RUN_FROM_PACKAGE` or worker/build settings onto Flex; keep its
portal-managed runtime/deployment configuration.

### 2.4 Foundry resource and project

1. **Create a resource**: search for **Microsoft Foundry** and create a Foundry resource in the
   platform group, using an approved region that supports your chosen chat model.
2. Use the current Foundry resource/project experience, not a legacy hub-based project.
   The repository expects an `AIServices` account with a current project API.
3. Open the resource -> **Go to Foundry portal** / **Launch studio**.
4. Select this resource and create project **`drift-investigation`** under it.
   If project creation offers a new account, select the account you just created instead.
5. Record the project's managed identity principal ID and copy its **project endpoint**.
   The expected form is:

   ```text
   https://<resource>.services.ai.azure.com/api/projects/<project>
   ```

Do not use an Azure OpenAI endpoint, connection string, ARM ID, or classic assistant project.
If the wizard creates a default model or agent, inventory it to avoid duplicate deployments.
Model selection and creation of the repository's agent happen in phase 5.

### 2.5 Azure AI Search service

1. **Create a resource -> Azure AI Search -> Create**.
2. Choose the platform group, unique service name, approved region, and suitable tier.
   **Basic** matches the repository's development default; review production capacity separately.
3. Create and record the HTTPS service URL:
   `https://<service>.search.windows.net`.
4. **Settings -> Keys -> API access control**: select **Role-based access control** and save.
   For an existing service with key-based consumers, use an approved migration rather than
   abruptly breaking them.

Do not use an import-data/vector wizard yet. Phase 6 creates the exact index the code expects.

### 2.6 Terraform backend Storage

1. Create another **Standard StorageV2** account in the state group. Do not reuse host Storage.
2. Require secure transfer, disable anonymous Blob access, and configure approved Blob
   versioning, soft delete, retention, and network restrictions.
3. **Data storage -> Containers -> + Container**: create **`tfstate`**, access level **Private**.
4. Do not upload an invented/empty state file. Terraform initializes and manages state later.

This backend is needed for scheduled drift detection, not merely for posting a sample plan.

### 2.7 Entra application and GitHub federation

1. **Microsoft Entra ID -> App registrations -> New registration**: create a single-tenant
   application named `tdip-drift-reader`. No redirect URI is needed.
2. Record **Application (client) ID** and **Directory (tenant) ID**. Confirm the corresponding
   enterprise application/service principal exists.
3. **Certificates & secrets -> Federated credentials -> Add credential**: choose GitHub Actions,
   enter owner/repository, entity type **Environment**, and environment **`dev`**.
4. Confirm issuer `https://token.actions.githubusercontent.com`, subject
   `repo:<owner>/<repository>:environment:dev`, and audience `api://AzureADTokenExchange`.
5. Do not create a client secret. Match repository/environment spelling and case exactly.

**Phase 2 complete:** All resource shells and principals exist. Model, agent, index, and code
deployment are intentionally still pending.

## 3. Assign RBAC, networking, and diagnostics

### 3.1 Role assignments

At each target resource/project, open **Access control (IAM) -> Add role assignment**, choose
the role and exact principal, then **Review + assign**. Project access may be managed through
Foundry. Distinguish the three identities: **your operator**, **Function identity**, and
**GitHub service principal**.

| Principal | Scope | Role / permission |
| --- | --- | --- |
| Operator creating/editing agents | Foundry project | **Foundry User**. |
| Operator deploying the model | Foundry resource | **Foundry Account Owner**, or an approved narrower role with deployment permissions. |
| Foundry project managed identity | Parent Foundry resource | **Foundry User**; verify any automatically created assignment. |
| Function system identity | Foundry project | **Foundry User**, matching the repository. |
| Operator running document upload | Search service | **Search Service Contributor** + **Search Index Data Contributor**. |
| Function system identity | Search service | **Search Index Data Reader**. |
| Operator using Search Explorer (if different) | Search service | **Search Service Contributor** + **Search Index Data Reader**. Data Contributor already grants content read access. |
| Function identity and operator testing logs | Log Analytics workspace | **Log Analytics Reader**. |
| GitHub service principal | Monitored target scopes | **Reader**; add narrowly scoped read permissions only if provider/data-source operations require them. |
| Operator and GitHub service principal | State Storage account/container | **Storage Blob Data Contributor**, including state lease/locking access. |
| Operator publishing code | Function App | **Website Contributor** or an approved role permitting Function code deployment; this is separate from AI data access. |

Foundry User may still appear as **Azure AI User**. A narrower **Foundry Agent Consumer** role
is available for inference-only use; this guide retains the repository's runtime assignment.
Do not grant the Function Account Owner, Search write access, or Terraform apply privileges.
Do not give the scheduled read-only workflow subscription Owner.

**Only for identity-based Function Storage:** complete the Functions Storage role requirements
for the chosen plan. Host Blob access uses **Storage Blob Data Owner**; queue operations can
require **Storage Queue Data Contributor**, and extensions may require additional roles.
Flex deployment-container access uses **Storage Blob Data Contributor** for its selected deployment
identity. Configure the corresponding identity-based host/deployment settings; do not just assign
roles and leave a broken connection string. Use the official Storage reference at the end.
These are not needed to authorize host access when using a valid account-key connection.

Allow RBAC propagation, often 5-10 minutes. Reopen IAM and verify principal IDs and scopes.
Operator playground success does not prove the Function identity can access the same service.
Review any existing service-principal environment credentials so `DefaultAzureCredential` does
not unintentionally select a different runtime identity.

### 3.2 Network access

- Ensure the Function can reach Foundry, Search, Log Analytics, and host/deployment Storage.
- Ensure the operator can reach Foundry/Search data endpoints and the Function publishing endpoint.
- Ensure GitHub's runner can reach Azure APIs, state Storage, and the Function HTTP endpoint.
- Public-endpoint development access must follow organizational policy. For private endpoints,
  create the approved VNet integration, private endpoints, DNS zones/links, and routes before
  continuing. Use a network-connected runner for private-only endpoints.
- IAM does not bypass a firewall. A visible management blade does not prove data-plane access.

No Foundry-to-Search network exception replaces Function access: the Function queries Search.

### 3.3 Subscription Activity Log export

1. **Subscriptions -> monitored subscription -> Activity log -> Diagnostic settings ->
   Add diagnostic setting**.
2. Enable **Administrative** and **Policy**; select **Send to Log Analytics workspace**.
3. Select the workspace from phase 2, name the setting, and save.
4. Reopen it and verify categories/destination. Repeat for other monitored subscriptions if needed.

This is subscription-level diagnostics, not Function diagnostics. New exports do not backfill
all historical events. Application Insights monitors the application; it does not replace this export.

**Phase 3 complete:** Resource creation and access configuration are finished. Resolve missing
permissions/network paths before creating models, uploading documents, or publishing.

## 4. Prepare the local environment

Run commands in **PowerShell from the repository root**. Replace all angle-bracket placeholders.
Use one terminal so environment variables remain available. Stop after any failed command.

```powershell
python --version
az version
terraform version

# Create only if .venv does not already exist.
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r .\src\function-app\requirements.txt
az login --tenant "<tenant-id>"
az account set --subscription "<subscription-id>"
az account show --query "{subscription:id,tenant:tenantId}" --output table
```

Use Python 3.12 for the environment. Do not install the obsolete umbrella `azure` package.
These tools publish code and initialize application data; Azure resource creation remains manual.

## 5. Deploy the Foundry model and create the prompt agent

### 5.1 Model deployment in Foundry portal

1. Open the selected resource/project in Foundry portal -> model catalog/deployments.
2. Select a chat model supported by **prompt agents and the Responses API** in your region.
3. Deploy it, choose an approved deployment type/capacity/content filter, and wait for **Ready**.
4. Record the **deployment name**, which may differ from the catalog model name.

The application does not train or fine-tune a model. Reuse a compatible default deployment if
the project wizard already created one. Catalog availability alone does not guarantee quota.

### 5.2 Create the versioned agent

```powershell
$env:FOUNDRY_PROJECT_ENDPOINT = "https://<resource>.services.ai.azure.com/api/projects/<project>"
$env:FOUNDRY_AGENT_NAME = "terraform-drift-investigator"
$env:FOUNDRY_MODEL_DEPLOYMENT = "<actual-chat-deployment-name>"
python .\scripts\create_foundry_agent.py
```

The script reads [recommendation-agent/prompt.txt](../src/agents/recommendation-agent/prompt.txt).
Record its printed agent name/version. Re-running creates another version, so do not retry blindly.
The Function selects by name and currently exposes no version-pin setting.
Do not create an agent for each helper folder or use a classic assistant ID.

## 6. Create the Search index and upload documents

1. Review [knowledge/README.md](../knowledge/README.md) and add approved UTF-8 `.md` or `.txt`
   runbooks/standards under `knowledge`. Include relevant resource/property terms such as
   `azurerm_resource_group` and `tags.environment`.
2. Exclude secrets, raw Terraform state/plans, credentials, and unapproved personal/internal data.
3. Keep documents focused and within Search document/request limits. The script stores each
   non-empty file as one document; it does not chunk, OCR, or read PDF/Word files.
4. Run:

   ```powershell
   $env:AI_SEARCH_ENDPOINT = "https://<search-service>.search.windows.net"
   $env:AI_SEARCH_INDEX = "platform-knowledge"
   python .\scripts\index_documents.py
   ```

5. Require `Indexed <N> document(s) into 'platform-knowledge'.` without rejected-document errors.

The script creates the index and pushes documents directly. No Blob data source, Search indexer,
skillset, embedding deployment, or vector configuration is required.

Expected schema, created by the script:

| Field | Type | Key | Searchable | Filterable | Retrievable |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `Edm.String` | Yes | No | Yes | Yes |
| `title` | `Edm.String` | No | Yes | No | Yes |
| `content` | `Edm.String` | No | Yes | No | Yes |
| `source` | `Edm.String` | No | No | Yes | Yes |

`id` hashes the relative path; `title` comes from the filename; `source` is the relative path.
The Function selects `title`, `content`, and `source`. Do not substitute wizard-generated fields.
An incompatible shared index should be replaced with a separately named, validated index, not
deleted blindly.

## 7. Configure and deploy the Function App

### 7.1 Save application settings in Azure portal

**Function App -> Settings -> Environment variables** (or **Configuration -> Application settings**):

| Setting | Value |
| --- | --- |
| `FOUNDRY_PROJECT_ENDPOINT` | Project endpoint copied from Foundry. |
| `FOUNDRY_AGENT_NAME` | `terraform-drift-investigator`, matching phase 5 exactly. |
| `AI_SEARCH_ENDPOINT` | Search service HTTPS URL. |
| `AI_SEARCH_INDEX` | `platform-knowledge`. |
| `LOG_ANALYTICS_WORKSPACE_ID` | Workspace **GUID**, not ARM resource ID. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Connection string for the linked Application Insights component. |

Save/apply and allow restart. Keep the wizard's host/deployment Storage settings intact.
On Flex, preserve portal-managed runtime configuration; do not add classic-only settings.
On classic/Premium, retain required Python worker/runtime settings.

`FOUNDRY_MODEL_DEPLOYMENT` belongs to the **agent creation script**, not Function runtime.
Foundry/Search API keys are not used. Local terminal variables and local settings do not
automatically become Azure application settings.

### 7.2 Publish the code using Azure CLI

Run from the **repository root** with phase 4's Python environment and Azure login active.
This updates code in the existing Function App; it does not create resources.

**1. Select the app and confirm CLI support:**

```powershell
$resourceGroup = "<function-app-resource-group>"
$functionApp = "<function-app-name>"
az account set --subscription "<subscription-id>"
az functionapp show --resource-group $resourceGroup --name $functionApp `
    --query "{name:name,state:state,kind:kind,plan:serverFarmId}" --output table
az functionapp deployment source config-zip --help
```

Require the correct app and support for `--build-remote`. If unsupported, update Azure CLI
using the approved installation method before continuing.

**2. Create a source ZIP with the Function files at its root:**

The explicit file list below packages the current Python v2 application, not the legacy
`investigate` folder. It excludes local settings, virtual environments, cached bytecode, and
Windows-installed dependencies.

```powershell
$zipPath = Join-Path $env:TEMP ("tdip-function-" + [guid]::NewGuid().ToString("N") + ".zip")
@'
import sys
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path("src") / "function-app"
files = [root / name for name in (
    "function_app.py", "drift.py", "host.json", "requirements.txt"
)]
for directory in ("services", "models"):
    files.extend(
        path for path in (root / directory).rglob("*.py")
        if "__pycache__" not in path.parts
    )
for path in files:
    if not path.is_file():
        raise SystemExit(f"Required source file is missing: {path}")
with ZipFile(sys.argv[1], "w", ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.relative_to(root).as_posix())
print(f"Packaged {len(files)} files into {sys.argv[1]}")
'@ | python - "$zipPath"
if ($LASTEXITCODE -ne 0) { throw "Function packaging failed." }
python -m zipfile -l "$zipPath"
```

Verify `host.json`, `function_app.py`, and `requirements.txt` are directly at the ZIP root,
not inside `src/function-app` or another enclosing folder.

**3. Deploy with a Linux remote build:**

```powershell
try {
    az functionapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $functionApp `
        --src "$zipPath" `
        --build-remote true `
        --timeout 600
    if ($LASTEXITCODE -ne 0) { throw "Function deployment failed; inspect deployment logs." }
} finally {
    Remove-Item -LiteralPath $zipPath -ErrorAction Stop
}
```

The remote build installs [requirements.txt](../src/function-app/requirements.txt) for Linux.
Do not package your local Windows `.venv` or `.python_packages`. ZIP upload success alone is not
proof of a successful build/startup; complete section 7.3 and the phase 9 integration tests.

- **Flex Consumption:** A current CLI routes this command through the supported Flex deployment
  flow. Keep portal-managed deployment Storage/runtime configuration. Do not add
  `WEBSITE_RUN_FROM_PACKAGE`, `SCM_DO_BUILD_DURING_DEPLOYMENT`, or `ENABLE_ORYX_BUILD` on Flex.
- **Linux classic Consumption/Premium:** Remote source builds must not be forced to run from an
  existing `WEBSITE_RUN_FROM_PACKAGE` setting. If that setting is present, remove it from the
  app's Environment variables before this remote-build deployment. The command requests remote
  build; inspect build logs to confirm dependencies were installed.
- If deployment fails or times out, inspect the portal's deployment diagnostics/build logs and
  Function startup errors before retrying. Do not change network restrictions or enable basic
  publishing credentials as a blind workaround. A timed-out client may leave a deployment running.

### 7.3 Post-deployment checks and caller key

1. Confirm publish/build success. Azure portal -> Function App -> **Functions** must list
   **`investigate`**. If absent, inspect deployment logs and startup exceptions before proceeding.
2. Reopen application settings and verify all six values in section 7.1.
3. Recheck the system identity and its Foundry, Search, and Logs roles; code publishing does not
   grant these permissions.
4. **Functions -> investigate -> Get function URL**: record the actual HTTPS
   `/api/investigate` URL without its `?code=...` query string.
5. Obtain a Function-scoped key securely. Do not paste it into this document, Git, screenshots,
   or a non-secret GitHub variable. Configure its GitHub secret in phase 8.

## 8. Configure Terraform tracking and GitHub scheduling

**Important:** Terraform detects drift only for resources already in its matching configuration
and state. Creating a private container or scanning a subscription does not establish a baseline.

The existing [development root](../environments/dev/main.tf) describes the platform stack.
It creates resources if applied and is not an automatic monitor of every manually created resource.
Do not run the apply workflow for this manual route or import a Flex app into its legacy Function
resource definition. A later platform apply can overwrite manual settings.

### 8.1 Track a manually created test resource

For a fresh setup, use the test group from phase 2 as a small, safe first target.
Create a dedicated Terraform root, for example `environments\manual-drift-test`, and put this
configuration in `main.tf` there:

```hcl
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {}
}

variable "subscription_id" {
  type = string
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "drift_test" {
  name     = "rg-tdip-drift-test"
  location = "<actual-resource-group-region>"
  tags = {
    environment = "dev"
  }
}
```

Match the actual name/location and **all existing tags**, including policy-added tags.
Provider auto-registration is disabled so this read-only example does not require registration
privileges; the administrator must register required providers beforehand.

From that Terraform root, use your phase 4 Azure login and phase 3 state/target permissions:

```powershell
$env:TF_VAR_subscription_id = "<subscription-id>"
terraform init `
  -backend-config="resource_group_name=<state-group>" `
  -backend-config="storage_account_name=<state-storage>" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=terraform-drift/manual-test.tfstate" `
  -backend-config="use_azuread_auth=true"
terraform import azurerm_resource_group.drift_test "/subscriptions/<subscription-id>/resourceGroups/rg-tdip-drift-test"
terraform state list
```

Run commands separately; stop if init/import fails. Import records the existing resource; it
does not create Azure resources. Do not re-import an address already present in state.
Commit the reviewed configuration and provider lock file, **not** state, saved plans, or `.terraform`.
For existing workloads, use their real root/backend/state instead of importing duplicate ownership.
Back up state through approved controls before migration/import.

### 8.2 Align the existing drift workflow

In [drift-investigation.yml](../.github/workflows/drift-investigation.yml), configure:

| Workflow surface | Fresh test-root value |
| --- | --- |
| `defaults.run.working-directory` | `environments/manual-drift-test` |
| Backend container | `tfstate` |
| Backend key | `terraform-drift/manual-test.tfstate`, matching init above |
| Terraform input | Keep `TF_VAR_subscription_id`; remove the unused `TF_VAR_name_suffix` mapping for this example root. |

Use forward slashes in the GitHub Linux runner path. For another workload, match its actual
directory/key and provide its required variables. Keep `id-token: write`, OIDC login,
refresh-only planning, and the existing Function request logic.

### 8.3 Set GitHub environment configuration

GitHub -> **Settings -> Environments -> dev**. Add environment variables:

| Variable | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | Phase 2 app's Application/client ID. |
| `AZURE_TENANT_ID` | Entra Directory/tenant ID. |
| `AZURE_SUBSCRIPTION_ID` | Monitored subscription ID. |
| `TFSTATE_RESOURCE_GROUP` | State group name. |
| `TFSTATE_STORAGE_ACCOUNT` | State account name. |
| `DRIFT_FUNCTION_URL` | Actual HTTPS `/api/investigate` URL, no `code` parameter. |

Add **`DRIFT_FUNCTION_KEY`** as an environment **secret**. The existing development root also
needs `TF_NAME_SUFFIX`; the dedicated example root above does not.

Ensure the workflow is on the default branch, Actions is enabled, the `dev` environment's
protection rules allow the intended unattended schedule, and the runner has network access.
The schedule is `17 */4 * * *`: every four hours at minute 17 **UTC**, best-effort.
No Azure timer Function or Logic App is needed.

## 9. Test only after configuration and deployment are complete

Run these checks in order. A resource showing **Succeeded** is not an integration test.

### 9.1 Foundry and Search checks

1. **Foundry -> model deployment**: confirm Ready; ask a harmless question in the model playground.
2. **Foundry -> Agents -> terraform-drift-investigator**: verify version, deployment name, and
   instructions against the script output and repository prompt.
3. In the agent playground, ask:

   ```text
   Resource azurerm_resource_group.drift_test has tags.environment changed from dev to manual-test.
   No Activity Log or PIM evidence is supplied. Explain facts, uncertainty, risk, and reversible
   next steps. Do not execute changes or invent an actor.
   ```

   Expect Summary, Evidence, Risk, and Recommended next steps. Playground tests use your operator
   identity and do not automatically query this application's Search index.
4. **Azure portal -> Search -> Indexes -> platform-knowledge**: verify phase 6's fields.
5. **Search Explorer -> JSON view**, using Entra/RBAC authentication, run:

   ```json
   {
     "search": "*",
     "count": true,
     "top": 3,
     "select": "title,content,source"
   }
   ```

6. Require a positive count and non-empty approved content/source. Repeat with
   `"search": "azurerm_resource_group azurerm_resource_group.drift_test tags.environment"`.
   Relevant guidance must be returned. Count summaries can lag after ingestion.

### 9.2 Activity export check

In the workspace's **Logs**, run:

```kusto
AzureActivity
| where TimeGenerated > ago(1h)
| project TimeGenerated, ResourceId, Caller, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc
| take 20
```

Require events from the monitored subscription. If empty, perform an approved harmless management
operation, wait for ingestion, and retry. A missing table can mean export has not ingested yet.

### 9.3 Sample HTTP integration test

Azure portal -> Function App -> **Functions -> investigate -> Code + Test -> Test/Run**:
select **POST**, `Content-Type: application/json`, and paste
[refresh-drift-plan.json](../samples/refresh-drift-plan.json). Supply the key if required.
For a deployment where portal Test/Run is unavailable, run this from the repository root:

```powershell
$uri = "https://<actual-function-hostname>/api/investigate"
$secureKey = Read-Host "Function key" -AsSecureString
$key = [System.Net.NetworkCredential]::new("", $secureKey).Password
try {
    $report = Invoke-RestMethod -Uri $uri -Method Post `
        -ContentType "application/json" -Headers @{ "x-functions-key" = $key } `
        -InFile ".\samples\refresh-drift-plan.json"
    $report | ConvertTo-Json -Depth 30
} finally {
    Remove-Variable key, secureKey -ErrorAction SilentlyContinue
}
```

| Acceptance check | Required result |
| --- | --- |
| HTTP / parser | HTTP 200, `drift_count: 1`, `tags.environment` changes from `dev` to `manual-test`. |
| Search | `drifts[0].knowledge_evidence` contains relevant `title`, `content`, `source`. |
| Foundry | Non-empty Markdown `recommendation`, bounded by supplied evidence. |
| Warnings | No Search/Foundry failure warnings; inspect any Activity Log failure. |
| Evidence honesty | No invented actor, PIM activation, or verified policy violation. |

The sample's resource ID is fictitious, so empty activity results are expected. Test real
activity correlation next. **HTTP 200 alone is not success:** missing settings can return empty
Search evidence or a null recommendation without warnings, and service exceptions can produce
200 with warnings. A no-drift request does not exercise Search or Foundry.

### 9.4 Real drift and scheduled-run test

1. In the monitored Terraform root, run:

   ```powershell
   terraform plan -refresh-only -detailed-exitcode
   $LASTEXITCODE
   ```

   Require exit **0** for the starting baseline. Exit **2** means existing drift; investigate
   before continuing. Other codes are errors. A normal plan can separately expose configuration
   mismatches; do not apply it automatically.
2. In Azure portal -> test resource group -> **Tags**, change only `environment` from `dev`
   to `manual-test`. Do not modify the Terraform configuration or refresh/apply the state baseline.
3. Wait for Activity Log export ingestion. GitHub -> **Actions -> Terraform Drift Investigation ->
   Run workflow**.
4. Require OIDC login/backend initialization success, plan exit **2**, and execution of
   **Send drift to investigation Function**. Inspect the JSON: exact test resource/tag, non-empty
   Search evidence/recommendation, and matching activity evidence without dependency warnings.
5. In Azure portal, restore the test tag to `dev` through the approved change process.
   Run the workflow again; require exit **0** and the no-drift path.
6. Verify a later scheduled run in GitHub. Schedules can be delayed; environment approval rules
   can prevent unattended execution.

Do not run `terraform apply -refresh-only` before proving detection: it accepts observed Azure
values into state rather than restoring the resource. Never test by changing production controls.
Azure portal validates services; GitHub validates workflow/scheduling; Terraform validates tracking.

### 9.5 Confirm telemetry and diagnose failures

In linked Application Insights -> **Logs**:

```kusto
requests
| where timestamp > ago(30m)
| where url has "/api/investigate"
| project timestamp, operation_Id, resultCode, success, duration
| order by timestamp desc
```

Use **Failures** and correlated exceptions/traces to diagnose the same operation. Direct workspace
queries may use `AppRequests`, `AppTraces`, and `AppExceptions` with different column names.
Do not log entire plans, keys, or sensitive evidence.

| Failure | Check first |
| --- | --- |
| Function absent/startup failure | Publish directory, dependency build logs, Python version, host/deployment Storage access. |
| HTTP 401/403 | Function key and any additional App Service Authentication/access restrictions. |
| HTTP 400/413 | Terraform show JSON shape and the Function's 5 MiB body limit. |
| Foundry unavailable | Exact project endpoint/agent name, compatible ready deployment, Function identity/project RBAC, quota, network. |
| Search unavailable/empty | Entra mode, Function Reader role, endpoint/index, schema, document count, realistic query. |
| Activity missing | Real resource ID, workspace GUID, export destination/categories, ingestion delay, 30-day lookback, Logs role. |
| Scripts work but Function fails | Different identities, Azure app settings, and Function outbound networking. |
| Workflow never invokes Function | Correct non-empty tracked state, plan exit 2, step conditions, default branch/environment configuration. |
| Workflow login/state denied | Federated subject/audience, target Reader and state Blob role, backend key/network. |

## 10. Sign-off and ongoing maintenance

- [ ] All resources exist in the intended subscription/regions.
- [ ] Operator, Function, project, and workflow identities have the correct scoped roles.
- [ ] Network paths, host/deployment Storage, and subscription export are working.
- [ ] Model/agent and Search schema/documents pass portal checks.
- [ ] Function code/settings are deployed and sample test returns actual AI evidence/recommendation.
- [ ] A tracked real test resource produces drift and matching activity evidence.
- [ ] Restoration produces no drift and a later scheduled run succeeds.
- [ ] Test date, resource names, agent version, index/document count, and sanitized evidence recorded.

After approved knowledge edits, rerun the indexing script. Stable source paths overwrite the same
document IDs; deleted/renamed files are **not** removed automatically. Remove obsolete documents
through approved Search maintenance, or build/validate a replacement index before switching.
The included knowledge README alone is not your organization's complete approved standards.

After prompt changes, review the new agent version and repeat the integration test. Rotate exposed
Function keys and update the GitHub secret. Monitor costs/quota, telemetry retention, state recovery,
and identity access. Do not enable a future infrastructure apply until manual resource ownership
and configuration are reconciled.

## References

- [Create a Function App in Azure portal](https://learn.microsoft.com/azure/azure-functions/functions-create-function-app-portal)
- [Functions Storage and identity configuration](https://learn.microsoft.com/azure/azure-functions/functions-reference#connecting-to-host-storage-with-an-identity)
- [Flex deployment settings](https://learn.microsoft.com/azure/azure-functions/flex-consumption-how-to)
- [Azure CLI Function ZIP deployment](https://learn.microsoft.com/cli/azure/functionapp/deployment/source#az-functionapp-deployment-source-config-zip)
- [Foundry SDK and project endpoints](https://learn.microsoft.com/azure/foundry/quickstarts/get-started-code)
- [Foundry RBAC](https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry)
- [Search RBAC](https://learn.microsoft.com/azure/search/search-security-rbac)
- [Search Explorer](https://learn.microsoft.com/azure/search/search-explorer)
- [Activity Log export](https://learn.microsoft.com/azure/azure-monitor/essentials/activity-log)
- [GitHub OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
- [Terraform Azure backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Terraform import](https://developer.hashicorp.com/terraform/cli/import)
