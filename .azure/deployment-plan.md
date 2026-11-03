# Azure Deployment Plan

> **Status:** Approved — implementation complete; Docker validation remains blocked

Generated: 2026-11-02

## Follow-up: Provision the MCP Gateway Container App in the Dev Root

The Function App precondition is failing because `mcp_gateway_url` is empty. The user selected the
dev Terraform root, a new ACR/build workflow, and external HTTPS ingress protected by Microsoft Entra
authentication for the Function App managed identity.

### Confirmed decisions

- Add the MCP Gateway Container App to `environments/dev`, in the root-managed Container Apps environment.
- Create ACR `acrtdipdev001` in the dev root's resource group (`rg-tdip-a1b2c3`) and publish the image
  `acrtdipdev001.azurecr.io/mcp-gateway:v1`.
- Use external HTTPS ingress, but require Entra authentication and restrict accepted callers to the
  Function App managed identity. Do not expose unauthenticated tool endpoints.
- Reuse the existing GitHub OIDC app registration (`github`, client ID
  `fa1bd01c-f139-4721-a01b-2db798cb826f`) as the gateway API registration; adopt it through a
  Terraform import block and preserve its existing owner and Microsoft Graph permission declarations.
- Keep subscription `5e546d2f-02ec-419a-8305-ad234518d98f` and region `uksouth`.
- Author Terraform and CI workflow changes only. Do not run `terraform apply`, deploy, or grant Azure
  or Graph permissions during this task.

### Findings and policy constraints

- `environments/dev` has an environment but no Container App; its Function App still consumes the
  empty `mcp_gateway_url` variable.
- No ACR exists in the confirmed subscription, and the Azure inventory returned no resources in
  `ddfdgv`. The root's configured resource group is `rg-tdip-a1b2c3`. ACR names are globally unique;
  Azure may reject `acrtdipdev001` if another tenant already owns it.
- The gateway Dockerfile starts `app:app` although the FastAPI instance is in `server.py`, and its
  build context does not include the sibling `common` and `tools` packages. `routes.py` imports a
  missing `tools.search` module. The Entra/PIM/change-analysis tools already acquire bearer tokens,
  but use the default credential chain rather than the shared Container Apps managed-identity
  credential.
- Subscription policies include the Security Center audit set and MFA-required write/delete
  policies. The tag policy found applies only to the Cloud Shell resource group; no policy found
  blocks the planned region, ACR, or Container Apps resources.
- The Function App's current MCP client sends unauthenticated requests. It must acquire an access
  token for the gateway API using its managed identity. The gateway must enforce Entra auth, allow
  only that caller, and leave `/health` unauthenticated for Container Apps health probes.
- Graph application-role grants require suitable Microsoft Graph permissions and tenant admin
  consent for the Terraform identity. The GitHub OIDC identity also needs ACR push and Container App
  update permissions, scoped to the new resources.

### Implementation plan

1. In `environments/dev`, add a Basic ACR with admin credentials disabled; a system-assigned
   Container App identity; an `AcrPull` grant; the gateway roles (`Monitoring Reader`, `Log Analytics
   Reader`, subscription `Reader`, and `Search Index Data Reader`); and the existing Function App
   roles/settings.
2. Import the existing single-tenant GitHub OIDC app registration into Terraform, preserve its
   existing owner and Graph permission declarations, add the API identifier URI and
   `Gateway.Invoke` role, assign that role to the Function App managed identity, and configure
   Container Apps authentication through `Microsoft.App/containerApps/authConfigs`. Require
   HTTPS/401 for unauthenticated callers, restrict the audience/caller, and exempt only `/health`.
   Assign the gateway identity the requested Graph application roles (`User.Read.All`,
   `Directory.Read.All`, `AuditLog.Read.All`, and `RoleManagement.Read.Directory`).
3. Derive `MCP_GATEWAY_URL` from the Container App FQDN so Terraform creates the gateway before the
   Function App; pass the required settings to the Function App and the gateway's subscription,
   workspace, and Search settings to the Container App. Remove the manually supplied empty URL from
   tfvars and CI.
4. Repair the gateway Docker packaging, entry point, and missing Search tool; consistently use the
   Container Apps managed identity for Azure SDK and Graph calls. Add an OIDC-protected, manually
   triggered GitHub workflow that builds/pushes the `v1` image and updates the Container App using
   managed identity. Grant that workflow identity only `AcrPush` and scoped Container App update
   access.
5. Follow the Container Apps ACR bootstrap pattern: Terraform initially creates the app with a
   public placeholder image and no registry credentials; after the first approved deployment, the
   image workflow pushes `mcp-gateway:v1`, configures managed-identity registry access, and updates
   the app. The Function App receives the final gateway URL during Terraform creation but gateway
   tool calls will not work until the image workflow completes.
6. Update deployment docs and Terraform CI validation to reflect the dev-root ownership and the
   two-stage image bootstrap. Preserve unrelated worktree changes and existing state. The explicitly
   approved import is limited to the existing GitHub app registration; do not import, move, destroy,
   or apply other resources.

### Approval

Approved by the user. The implementation is complete. Read-only Terraform validation is in scope;
no Azure apply/deployment is authorized.

### Validation

After plan approval: format and validate Terraform locally, verify Docker build/startup and health,
and lint/check the workflow if tooling is available. Do not apply or deploy.

## Follow-up: Configure Existing Azure Storage Backend

The user supplied the existing state storage account resource ID:
`/subscriptions/5e546d2f-02ec-419a-8305-ad234518d98f/resourceGroups/defaultresourcegroup-wus3/providers/Microsoft.Storage/storageAccounts/csg100320031401b3a8`.

### Approved scope

- Configure the `azurerm` backend in `environments/dev/backend.tf` with the supplied subscription, resource group, and storage account.
- Retain the existing backend container (`tfstate`), state key (`terraform-drift/dev.tfstate`), and Microsoft Entra/Azure AD authentication (`use_azuread_auth = true`); do not store storage keys or other secrets in Terraform files.
- Do not change the GitHub workflows; their explicit backend-config arguments continue to override backend block values in CI.
- Locally validate formatting and configuration without applying infrastructure or modifying remote state.

### Approval

Approved by the user: configure only the dev root backend; leave CI workflows unchanged.

## Follow-up: Restore Container Apps Environment in the Dev Root

The user reports that the Container Apps environment was deleted and requests its Terraform resource in the root module. The current worktree has deleted `modules/containerapps/main.tf` and `modules/containerapps/provider.tf`; this follow-up will not restore those files.

### Proposed scope

- Add `azurerm_container_app_environment` to `environments/dev/main.tf`.
- Derive its name, resource group, location, and Log Analytics workspace from resources already managed by the dev root rather than hardcoding the deleted environment's old manual resource group.
- Create a public (non-VNet-integrated) environment as selected by the user, with logs sent to the dev root's Log Analytics workspace.
- Do not deploy, apply, import/move Terraform state, or alter the separate Container Apps state. Before deployment, reconcile any stale ownership in that state to avoid two roots managing the same resource.
- Validate formatting and the dev Terraform root after the user approves this follow-up plan.

### Approval

Approved by the user: dev root owns the public Container Apps environment.

### Execution checklist

- [x] Confirm root ownership and public environment scope
- [x] Add the environment to the dev root and expose its outputs
- [x] Update deployment guidance for the new environment ownership
- [x] Run Terraform formatting and local validation

### Validation checks

### All validation checks pass

- [x] Terraform CLI and Azure CLI are installed; Azure CLI is authenticated
- [x] `terraform init` succeeds for `environments/dev`
- [x] `terraform fmt -check -recursive` succeeds
- [x] `terraform validate` succeeds
- [x] Read-only `terraform plan` succeeds; do not apply
- [x] `terraform state list` succeeds (no resource addresses were printed)
- [x] No unresolved Go-style `{{ .Env.* }}` Terraform template variables are present
- [x] `main.tfvars.json` is not used by this Terraform root (`terraform.tfvars` is used)
- [x] Static role-assignment review confirms the requested identities, roles, and scopes
- [x] Python source syntax checks pass for Function App and MCP source
- [ ] Gateway Docker image builds and `/health` responds (requires a running Docker engine)
- [x] YAML parsing succeeds for all five GitHub Actions workflow files
- [x] `git diff --check` succeeds when CRLF is treated as an end-of-line on Windows

The user explicitly approved the read-only plan and state-list checks. No apply, import, state
migration, or Azure resource changes are authorized.

## 1. Project Overview

**Goal:** Add a secured MCP Gateway Container App and image pipeline to the existing dev Terraform
root, remove the manually supplied empty gateway URL, and ensure the Function App receives the
gateway URL and required settings after its dependencies are created.

**Mode:** Modify an existing Azure application.

## 2. Requirements and Azure Context

| Attribute | Value |
|-----------|-------|
| Classification | Development |
| Scale | Development; no scale increase requested |
| Budget | Development; Basic ACR and a minimum gateway replica are planned |
| Subscription | `5e546d2f-02ec-419a-8305-ad234518d98f` |
| Region | `uksouth` |
| Deployment scope | Terraform and workflow code only; no Azure apply/deploy |
| Ingress | External HTTPS with Entra authentication for the Function App managed identity |
| Registry | Create `acrtdipdev001` in `rg-tdip-a1b2c3`; publish `mcp-gateway:v1` |

Azure policy inventory found subscription-level Security Center audit policies and MFA requirements
for resource write/delete actions. The tag policy found is scoped to the Cloud Shell resource group.
No policy found blocks the chosen region or planned resource types.

## 3. Components

| Component | Type | Technology | Path |
|-----------|------|------------|------|
| Drift investigation API | Serverless API | Python Azure Functions | `src/function-app` |
| MCP Gateway | HTTP API | FastAPI on Azure Container Apps | `src/mcp/activity-log-mcp` |
| Gateway image | Container image | Docker, Azure Container Registry | `src/mcp` |
| Infrastructure | IaC | Terraform AzureRM/AzAPI/AzureAD | `environments/dev`, `modules` |
| Image publishing | CI | GitHub Actions OIDC | `.github/workflows` |

## 4. Recipe

**Selected:** Existing pure Terraform workflow.

**Rationale:** The repository already has a Terraform dev root, remote backend, and Terraform CI.

## 5. Proposed Architecture

- Keep the existing public, non-VNet-integrated Container Apps environment in the dev root.
- Add the Container App with external HTTPS ingress on port 8000, system-assigned identity, health
  probe at `/health`, and Entra authentication. Only the Function App managed identity is an allowed
  application caller; unauthenticated tool routes return 401.
- Create a single-tenant Entra API registration and `Gateway.Invoke` application role. Configure the
  Function App managed identity to request `api://<gateway-api-client-id>/.default`; exempt only
  `/health` from authentication.
- Initially create the Container App using the documented public placeholder image. After the first
  Terraform deployment, a manually triggered OIDC workflow builds and pushes
  `acrtdipdev001.azurecr.io/mcp-gateway:v1`, configures identity-based ACR pull, and updates the app.
  The Function App is created with the correct URL in phase one but cannot call gateway tools until
  the image workflow completes.
- Derive the Function App's `MCP_GATEWAY_URL` from the Container App FQDN. Terraform references
  establish the resource dependency; remove the empty tfvars value and workflow override.
- Set Function App values `MCP_GATEWAY_URL`, `FOUNDRY_PROJECT_ENDPOINT`, `SEARCH_ENDPOINT`,
  `SEARCH_INDEX`, `APPLICATIONINSIGHTS_CONNECTION_STRING`, and the gateway token scope. Set gateway
  values for `SUBSCRIPTION_ID`, `LAW_WORKSPACE_ID`, `SEARCH_ENDPOINT`, and `SEARCH_INDEX`.
- Grant the Function App `Azure AI User`, `Search Index Data Reader`, and subscription `Reader`.
  Grant the gateway `Monitoring Reader`, workspace `Log Analytics Reader`, subscription `Reader`,
  `Search Index Data Reader`, and Graph app roles `User.Read.All`, `Directory.Read.All`,
  `AuditLog.Read.All`, and `RoleManagement.Read.Directory`.
- Grant the Container App identity `AcrPull`; grant the existing GitHub OIDC identity `AcrPush` on
  the new ACR and scoped Container App update rights. Do not enable ACR admin credentials.
- Fix the Docker build context/entry point, implement the imported Search tool, and replace
  placeholder Graph Authorization headers with managed-identity tokens.
- Preserve existing unrelated changes and Terraform state. Do not import/move/destroy resources.

Graph role assignment requires appropriate Microsoft Graph application permissions and tenant admin
consent. The Terraform identity also needs sufficient Graph permissions to read service principals
and manage the gateway app registration. Terraform identity permissions and the global availability
of `acrtdipdev001` remain deployment prerequisites.

## 6. Provisioning Limits and Deployment Boundary

No Azure resources, role assignments, or directory permissions will be provisioned by this task.
Terraform initialization, remote-state listing, and a read-only plan are permitted for validation;
no apply, deployment, import, or state migration is authorized. The first deployment must provision
the ACR and placeholder Container App before the image workflow is run; the workflow must then
complete before the Function App can successfully call the gateway.

## 7. Execution Checklist

### Planning
- [x] Inspect current Terraform, gateway source/image, workflows, and Azure policy/resource inventory
- [x] Confirm subscription, region, ACR approach, and secure ingress
- [x] Present the complete plan and obtain user approval

### After approval (code changes only)
- [x] Add ACR, Container App, Entra auth, role assignments, settings, and derived gateway URL
- [x] Repair gateway Docker packaging, Search implementation, and identity-based API calls
- [x] Add image build/push/update workflow and update Terraform CI and deployment documentation
- [ ] Run Terraform formatting/validation, Docker startup/health checks, and workflow validation
- [x] Set status to Approved and hand off to `azure-validate`

## 8. Validation and Deployment

Validation includes local checks and read-only access to the Azure backend and plan APIs; no
deployment execution is included. Azure resource deployment requires separate approval and the
required Azure RBAC/Graph administrator permissions.

### Validation proof

- PASS — Azure CLI is authenticated to subscription `5e546d2f-02ec-419a-8305-ad234518d98f`.
- PASS — `terraform init -input=false` in `environments/dev` initialized the configured remote
  backend successfully.
- PASS — `terraform fmt -check -recursive` from the repository root.
- PASS — `terraform validate -no-color` in `environments/dev`.
- PASS — `terraform state list` exited successfully; no resource addresses were printed.
- PASS — the Terraform root has no unresolved Go-style `{{ .Env.* }}` variables.
- PASS — Python AST parsing completed for 30 files under `src/function-app` and `src/mcp`.
- PASS — YAML parsing completed for all five `.github/workflows` YAML files.
- PASS — `git -c core.whitespace=cr-at-eol diff --check`.
- STATIC REVIEW — Function App roles are Azure AI User (Foundry project), Search Index Data Reader
  (Search service), Reader (subscription), and Log Analytics Reader (workspace). Gateway roles are
  Monitoring Reader and Reader (subscription), Log Analytics Reader (workspace), Search Index Data
  Reader (Search service), and AcrPull (ACR). The four requested Microsoft Graph application roles
  and scoped GitHub ACR/App role assignments are present.
- PASS — the read-only plan resolves all four Microsoft Graph application-role IDs and previews
  adoption of the existing `github` app registration, 32 other additions, one in-place app-role
  update, and zero destructions. The app preview preserves its existing owner and Microsoft Graph
  permission declarations. No apply or state import was performed.
- BLOCKED — Docker build and `/health` verification could not run. Both Docker Desktop's
  `desktop-linux` context and the default Docker context report that their named pipes are
  unavailable, despite the earlier readiness confirmation.
- NOTE — the provided validation preflight helper is incompatible with this Windows PowerShell
  invocation; its Terraform commands printed usage. The underlying Terraform checks were run
  directly. No apply, import, state migration, or deployment was run.

- No Azure resource apply or deployment was run.
