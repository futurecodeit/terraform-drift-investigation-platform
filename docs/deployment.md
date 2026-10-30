# Deployment Guide

This guide describes what is deployable from the current repository and the order to deploy it.
For the detailed portal-based setup, RBAC, Function publishing, and end-to-end test procedure, see
[Manual Setup from Scratch](./manual-steps.md).

## What this repository deploys

The Terraform root in [`environments/dev`](../environments/dev) currently provisions:

- A platform resource group
- Log Analytics and Application Insights
- A Microsoft Foundry account and project (not a model deployment or agent)
- Azure AI Search (not its index or documents)
- A Linux Function App, its hosting plan and host Storage account
- Function managed identity role assignments and subscription Activity Log diagnostics

The Terraform state Storage account and private `tfstate` container must be created separately
before Terraform initialization. The development root does not create its own backend.
Terraform also does not publish Function code, deploy a Foundry model/agent, or create the Search
index and upload knowledge; these are separate deployment steps below.

## Container Apps and MCP status

Container Apps and MCP servers are described in some architecture/design documents, but they are
not implemented in the current deployable stack. There is no Container Apps Terraform module or
resource in the development root, no MCP server source or Docker image in this repository, and no
Foundry MCP tool registration in the application or workflows.

The Function currently queries Activity Logs, AI Search, and Foundry directly through its service
clients. The Entra and PIM MCP components shown in design material are not part of this runtime.
Do not treat the old generic “build image / deploy Container App / register custom tools” steps as
completed deployment instructions. Add those steps only when the server implementations, image
publishing, Container Apps infrastructure, identity/network permissions, and Foundry tool
connections are added and tested.

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
`Microsoft.Insights`, `Microsoft.CognitiveServices`, `Microsoft.Search`, and
`Microsoft.Authorization`. Container Apps provider registration is not needed for this stack.

## 1. Configure Terraform state

Create the state resource group, Storage account, and private `tfstate` container outside this
Terraform root. Keep this backend separate from the Function's host Storage account. Enable
appropriate state access controls, retention, and recovery protections for your environment.

The backend block in [`environments/dev/backend.tf`](../environments/dev/backend.tf) is
intentionally empty. The deployment workflow supplies the backend configuration at initialization:

| Backend setting | Value |
| --- | --- |
| Resource group | Name of the pre-created state resource group |
| Storage account | Name of the pre-created state Storage account |
| Container | `tfstate` |
| Key | `terraform-drift/dev.tfstate` |
| Authentication | Azure AD / OIDC (`use_azuread_auth=true`) |

For local Terraform commands, sign in with `az login`, select the subscription, and initialize
from the development root with the same backend values:

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

## 2. Provision the Azure platform

The repository includes GitHub Actions workflows for provisioning:

1. Configure the GitHub `dev` environment with these **variables**:
   `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TF_NAME_SUFFIX`,
   `TFSTATE_RESOURCE_GROUP`, and `TFSTATE_STORAGE_ACCOUNT`.
2. Configure an Entra federated credential for the repository's `dev` GitHub environment. Do not
   create a client secret. Grant the GitHub service principal the minimum permissions needed for
   Terraform apply and state access.
3. Run **Actions → Terraform Apply → Run workflow** on the intended branch.
4. Review the run and Terraform outputs. Confirm that resources were created in the intended
   subscription and region.

The [`Terraform Apply` workflow](../.github/workflows/terraform-apply.yml) is intended to run `terraform apply`
against `environments/dev`. The [`Terraform Plan` workflow](../.github/workflows/terraform-plan.yml)
validates and plans changes on pull requests. The development root also has values in
[`terraform.tfvars`](../environments/dev/terraform.tfvars); confirm they match the target
environment before applying. GitHub-provided `TF_VAR_subscription_id` and `TF_VAR_name_suffix`
values override the corresponding local values.

Do not assume the apply creates a Container Apps environment, Key Vault, virtual network, or any
resources from modules that are not called by this Terraform root.

## 3. Configure Foundry and Search

Terraform creates the Foundry account/project and Search service only. After apply:

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
   permissions to create/populate the index. The Function identity needs Search Index Data Reader.
4. Create the index and upload approved `.md` / `.txt` knowledge documents:

   ```sh
   export AI_SEARCH_ENDPOINT="https://<search-service>.search.windows.net"
   export AI_SEARCH_INDEX="platform-knowledge"
   python scripts/index_documents.py
   ```

The index script creates the expected index schema and uploads files from `knowledge/`. It does
not configure vector search, embeddings, an indexer, or an MCP server.

## 4. Publish and configure the Function

Terraform creates the Function App and its managed identity, but it does not deploy the Python
application. The development root sets the Foundry project endpoint and agent name, Search endpoint
and index name, Log Analytics workspace GUID, and Application Insights connection string as app
settings. After apply, verify those settings and the Function identity's Foundry User, Search Index
Data Reader, and Log Analytics Reader roles at the appropriate scopes.

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
