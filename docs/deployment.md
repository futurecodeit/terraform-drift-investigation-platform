# Deployment Guide

This guide describes what is deployable from the current repository and the order to deploy it.
For the detailed portal-based setup, RBAC, Function publishing, and end-to-end test procedure, see
[Manual Setup from Scratch](./manual-steps.md).

## What this repository deploys

The Terraform root in [`environments/dev`](../environments/dev) currently provisions:

- A platform resource group
- A virtual network with separate Function integration, private endpoint, and Container Apps subnets
- Log Analytics, a public Container Apps environment, and Application Insights
- A Microsoft Foundry account and project (not a model deployment or agent)
- Azure AI Search (not its index or documents)
- A Linux Function App on the Elastic Premium plan, its host Storage account, and VNet integration
- An Azure Container Registry and an externally reachable MCP Gateway Container App
- Entra API authentication on the existing `github` app registration, restricted to the Function
  App managed identity
- Function and gateway managed-identity role assignments, Microsoft Graph application roles, and
  subscription Activity Log diagnostics

The dev root derives `MCP_GATEWAY_URL` from the gateway Container App's HTTPS FQDN. Terraform creates
the gateway app before the Function App, so no manually supplied URL is required. The Container Apps
environment is public and not VNet-integrated; the gateway's tool routes are protected by Entra
authentication, while `/health` is unauthenticated for health checks.

The Terraform state Storage account and private `tfstate` container must be created separately
before Terraform initialization. The development root does not create its own backend.
Terraform also does not publish Function code, deploy a Foundry model/agent, or create the Search
index and upload knowledge; these are separate deployment steps below.

## Container Apps and MCP status

The dev root owns the Container Apps environment, gateway app, ACR, and gateway permissions. It
reuses the existing GitHub OIDC app registration (`fa1bd01c-f139-4721-a01b-2db798cb826f`) for the
gateway API. A Terraform import block adopts it and adds the `Gateway.Invoke` application role and
API identifier URI while preserving its existing owner and Microsoft Graph permission declarations.
The Function App managed identity is assigned the gateway role and is the only allowed API caller.
Terraform initially uses a temporary Python HTTP placeholder so the first
apply can create the registry and app before the image exists. After that apply, run the manual
[`MCP Gateway Image` workflow](../.github/workflows/mcp-gateway-image.yml) to build and push the
gateway image, configure system-identity ACR pull, update the app, and smoke-test `/health`. The
Function App receives its final gateway URL during Terraform creation but cannot invoke the gateway
until that workflow completes.

## Prerequisites

- An Azure subscription and permissions to create the resources, assign the required RBAC roles,
  and configure subscription diagnostic settings.
- Azure CLI, Terraform 1.9+, Python 3.12, Git, and access to the GitHub repository.
- A globally unique suffix for the resources. The development variables require a 4–8 character
  lowercase alphanumeric `name_suffix`.
- A separate Azure Storage account and private `tfstate` container for the Terraform backend.
- A Foundry-supported region/model deployment and sufficient model quota.

Register the resource providers required by the deployed Terraform resources if they are not
already registered: `Microsoft.Resources`, `Microsoft.Storage`, `Microsoft.Web`,
`Microsoft.Insights`, `Microsoft.CognitiveServices`, `Microsoft.Search`, `Microsoft.Authorization`,
`Microsoft.Network`, and `Microsoft.App`.

## 1. Configure Terraform state

The state resource group, Storage account, and private `tfstate` container are managed outside this
Terraform root. Keep this backend separate from the Function's host Storage account. Enable
appropriate state access controls, retention, and recovery protections for your environment.

The backend block in [`environments/dev/backend.tf`](../environments/dev/backend.tf) is configured
for the supplied Storage account. The deployment workflows supply matching backend overrides at
initialization:

| Backend setting | Value |
| --- | --- |
| Resource group | Name of the pre-created state resource group |
| Storage account | Name of the pre-created state Storage account |
| Container | `tfstate` |
| Key | `terraform-drift/dev.tfstate` |
| Authentication | Azure AD / OIDC (`use_azuread_auth=true`) |

For local Terraform commands, sign in with `az login`, select the subscription, and initialize
from the development root:

```sh
cd environments/dev
az login
az account set --subscription "<subscription-id>"
terraform init \
  -backend-config="resource_group_name=<state-resource-group>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform-drift/dev.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform validate
terraform plan
```

Do not put credentials or backend secrets in the repository. Ensure the selected identity has
the required state Blob permissions.

## 2. Provision the Azure platform and gateway

1. Configure the GitHub `dev` environment variables, initialize the `environments/dev` backend, and
   run the Terraform Apply workflow. Terraform creates the platform, ACR, authenticated placeholder
   Container App, Function App, Entra app-role assignment, and Azure/Graph role assignments in
   dependency order.
2. After the apply succeeds, run **Actions → MCP Gateway Image → Run workflow** and keep the default
   image tag `v1` unless publishing another version. The workflow builds from the `src/mcp` context,
   pushes to ACR with OIDC, configures the Container App's system identity to pull, updates the
   running image, and checks the public `/health` route.
3. Confirm that unauthenticated requests to `/tools/*` return 401 and the Function App can call the
   gateway using its managed identity. Do not use the Function App before the image workflow
   succeeds.

The Function App identity receives `Azure AI User`, Search Index Data Reader, Log Analytics Reader,
and subscription Reader. The gateway identity receives Monitoring Reader, Log Analytics Reader,
Search Index Data Reader, subscription Reader, and the Graph application roles `User.Read.All`,
`Directory.Read.All`, `AuditLog.Read.All`, and `RoleManagement.Read.Directory`.

For CI-based provisioning, configure the GitHub `dev` environment with these **variables**:

1. Configure the GitHub `dev` environment with these **variables**:
   `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TF_NAME_SUFFIX`,
   `TFSTATE_RESOURCE_GROUP`, and `TFSTATE_STORAGE_ACCOUNT`.
2. Configure an Entra federated credential for the repository's `dev` GitHub environment. Do not
   create a client secret. The same OIDC identity needs Terraform permissions, ACR push, and scoped
   Container App update permissions; Terraform configures the latter two on the new resources.
3. Ensure the Terraform identity has the Azure role-assignment permissions and Microsoft Graph
   application permissions required to create the requested assignments. Graph permissions require
   tenant administrator consent.
4. Run **Actions → Terraform Apply → Run workflow** on the intended branch, then run the
   **MCP Gateway Image** workflow as described above.
5. Confirm the resources are in the intended subscription and region.

The [`Terraform Apply` workflow](../.github/workflows/terraform-apply.yml) is intended to run `terraform apply`
against `environments/dev`. The [`Terraform Plan` workflow](../.github/workflows/terraform-plan.yml)
validates and plans changes on pull requests. The development root also has values in
[`terraform.tfvars`](../environments/dev/terraform.tfvars); confirm they match the target
environment before applying. GitHub-provided `TF_VAR_subscription_id` and `TF_VAR_name_suffix`
values override the corresponding local values. The workflow also supplies
`TF_VAR_github_actions_client_id` from `AZURE_CLIENT_ID`.

The `Terraform Apply` workflow creates the gateway URL from the Container App resource; no
`MCP_GATEWAY_URL` GitHub variable or manually entered Terraform variable is required.

## 3. Configure Foundry and Search

Terraform creates the Foundry account/project and Search service only. After the shared-resource
stage:

1. In the Foundry project, deploy a compatible chat model and wait until it is ready.
2. Create the versioned prompt agent using the project endpoint and actual model deployment name:

   ```sh
   python -m venv .venv
   . .venv/bin/activate
   python -m pip install -r src/function-app/requirements.txt
   export FOUNDRY_PROJECT_ENDPOINT="https://<resource>.services.ai.azure.com/api/projects/<project>"
   export FOUNDRY_AGENT_NAME="terraform-drift-investigator"
   export FOUNDRY_MODEL_DEPLOYMENT="<model-deployment-name>"
   python scripts/create_foundry_agent.py
   ```

   The script reads the recommendation prompt from `src/agents/recommendation-agent/prompt.txt`.
   It creates a new agent version when run; record the version it reports.
3. Grant the operator identity Search Service Contributor and Search Index Data Contributor
   permissions to create/populate the index. The Function and Gateway identities receive
   Search Index Data Reader from Terraform.
4. Create the index and upload approved `.md` / `.txt` knowledge documents:

   ```sh
   export AI_SEARCH_ENDPOINT="https://<search-service>.search.windows.net"
   export AI_SEARCH_INDEX="platform-knowledge"
   python scripts/index_documents.py
   ```

The index script creates the expected index schema and uploads files from `knowledge/`. It does
not configure vector search, embeddings, an indexer, or an MCP server.

## 4. Publish and configure the Function

Terraform creates the Function App after the gateway Container App and derives its URL automatically.
It sets `MCP_GATEWAY_URL`, `MCP_GATEWAY_SCOPE`, `FOUNDRY_PROJECT_ENDPOINT`, `SEARCH_ENDPOINT`,
`SEARCH_INDEX`, `APPLICATIONINSIGHTS_CONNECTION_STRING`, the agent name, and Log Analytics workspace
GUID as app settings. After apply, run the MCP Gateway Image workflow before testing tool calls.
Verify the Function identity's `Azure AI User`, Search Index Data Reader, Log Analytics Reader,
subscription Reader, and `Gateway.Invoke` application role.

Publish the Python Function using the current Linux remote-build ZIP procedure in
[Manual Setup from Scratch, section 7](./manual-steps.md#7-configure-and-deploy-the-function-app).
That procedure packages the files under `src/function-app` correctly and verifies the discovered
`investigate` HTTP function. Do not use the old generic `func azure functionapp publish` command
as a substitute for the documented deployment method.

After publishing, verify the Function lists `investigate`, its app settings are present, and
`POST /api/investigate` is protected by a Function key. Store the key only in the GitHub
environment secret `DRIFT_FUNCTION_KEY`; set the key-free HTTPS endpoint in the `DRIFT_FUNCTION_URL`
environment variable.

## 5. Configure and test drift investigation

The scheduled workflow uses GitHub OIDC to initialize the same backend, run a Terraform
refresh-only plan, and call the Function only when drift is detected. It does not monitor every
resource in the subscription: a resource must be represented in the Terraform configuration and
the matching state.

Before enabling it, configure the GitHub `dev` environment with the variables listed in section 2,
plus `DRIFT_FUNCTION_URL`, and the secret `DRIFT_FUNCTION_KEY`. The workflow identity needs
read access to the monitored Terraform resources and Storage Blob access to the state. Ensure the
backend key and `working-directory` in
[`drift-investigation.yml`](../.github/workflows/drift-investigation.yml) match the Terraform root
being monitored.

The workflow runs on demand and every four hours at minute 17 UTC. Test with a safe, tracked
resource, confirm a clean baseline, make a reversible change, and run the workflow manually.
Verify that Terraform reports drift, the Function receives the plan, and the response contains the
expected evidence and recommendation. Restore the resource and verify the next run reports no
drift. Follow [Manual Setup from Scratch, sections 8–10](./manual-steps.md#8-configure-terraform-tracking-and-github)
for the full state-tracking, permissions, acceptance criteria, and troubleshooting procedure.

Never run `terraform apply -refresh-only` before the detection test: it updates state to accept the
observed value and can erase the drift signal.
