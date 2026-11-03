locals {
  resource_group_name             = "rg-${var.name_prefix}-${var.name_suffix}"
  storage_account_name            = "st${var.name_prefix}${var.name_suffix}"
  foundry_name                    = "fdry${var.name_prefix}${var.name_suffix}"
  search_name                     = "srch-${var.name_prefix}-${var.name_suffix}"
  function_name                   = "func-${var.name_prefix}-${var.name_suffix}"
  workspace_name                  = "law-${var.name_prefix}-${var.name_suffix}"
  insights_name                   = "appi-${var.name_prefix}-${var.name_suffix}"
  container_apps_environment_name = "cae-${var.name_prefix}-dev"
  mcp_gateway_name                = "ca-${var.name_prefix}-mcp-gateway"
  mcp_gateway_acr_name            = "acrtdipdev001"
  mcp_gateway_api_audience        = "api://${var.github_actions_client_id}"
}

# fa1bd01c-f139-4721-a01b-2db798cb826f

module "resource_group" {
  source = "../../modules/resource-group"

  resource_groups = { platform = local.resource_group_name }
  location        = var.location
  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

module "virtual_network" {
  source = "../../modules/virtual-network"

  name                = "vnet-${var.name_prefix}-${var.name_suffix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  depends_on = [module.resource_group]
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = local.workspace_name
  location            = var.location
  resource_group_name = local.resource_group_name

  depends_on = [module.resource_group]
}

resource "azurerm_container_app_environment" "mcp_gateway" {
  name                       = local.container_apps_environment_name
  location                   = var.location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = module.log_analytics.id

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "azurerm_container_registry" "mcp_gateway" {
  name                = local.mcp_gateway_acr_name
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }

  depends_on = [module.resource_group]
}

resource "azurerm_container_app" "mcp_gateway" {
  name                         = local.mcp_gateway_name
  resource_group_name          = local.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.mcp_gateway.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name    = "mcp-gateway"
      image   = "python:3.12-slim"
      cpu     = 0.25
      memory  = "0.5Gi"
      command = ["python", "-m", "http.server", "8000", "--bind", "0.0.0.0"]

      env {
        name  = "SUBSCRIPTION_ID"
        value = var.subscription_id
      }

      env {
        name  = "LAW_WORKSPACE_ID"
        value = module.log_analytics.workspace_id
      }

      env {
        name  = "SEARCH_ENDPOINT"
        value = module.ai_search.endpoint
      }

      env {
        name  = "SEARCH_INDEX"
        value = var.ai_search_index
      }

      liveness_probe {
        transport = "TCP"
        port      = 8000
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 8000
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      registry,
      template[0].container[0].command,
      template[0].container[0].image,
    ]
  }

  depends_on = [
    azurerm_container_registry.mcp_gateway,
    module.ai_search,
    module.log_analytics,
  ]
}

module "application_insights" {
  source = "../../modules/application-insights"

  name                = local.insights_name
  location            = var.location
  resource_group_name = local.resource_group_name
  workspace_id        = module.log_analytics.id

  depends_on = [module.resource_group]
}

module "foundry" {
  source = "../../modules/azure-ai-foundry"

  name              = local.foundry_name
  project_name      = var.foundry_project_name
  location          = var.location
  resource_group_id = module.resource_group.resource_group_ids["platform"]

  depends_on = [module.resource_group]
}

module "ai_search" {
  source = "../../modules/ai-search"

  name                = local.search_name
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = var.ai_search_sku

  depends_on = [module.resource_group]
}

module "function_app" {
  source = "../../modules/function-app"

  name                      = local.function_name
  location                  = var.location
  resource_group_name       = local.resource_group_name
  storage_account_name      = local.storage_account_name
  virtual_network_subnet_id = module.virtual_network.function_subnet_id
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
    FOUNDRY_PROJECT_ENDPOINT              = module.foundry.project_endpoint
    FOUNDRY_AGENT_NAME                    = var.foundry_agent_name
    MCP_GATEWAY_URL                       = "https://${azurerm_container_app.mcp_gateway.ingress[0].fqdn}"
    MCP_GATEWAY_SCOPE                     = "${local.mcp_gateway_api_audience}/.default"
    SEARCH_ENDPOINT                       = module.ai_search.endpoint
    SEARCH_INDEX                          = var.ai_search_index
    LOG_ANALYTICS_WORKSPACE_ID            = module.log_analytics.workspace_id
  }

  depends_on = [
    module.resource_group,
    module.virtual_network,
    module.log_analytics,
    module.application_insights,
    module.foundry,
    module.ai_search,
    azurerm_role_assignment.gateway_acr_pull,
    azurerm_role_assignment.gateway_monitoring_reader,
    azurerm_role_assignment.gateway_logs_reader,
    azurerm_role_assignment.gateway_subscription_reader,
    azurerm_role_assignment.gateway_search_reader,
  ]
}

resource "azurerm_role_assignment" "function_ai_user" {
  scope                            = module.foundry.project_id
  role_definition_name             = "Azure AI Administrator"
  principal_id                     = module.function_app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "function_search_reader" {
  scope                            = module.ai_search.id
  role_definition_name             = "Search Index Data Reader"
  principal_id                     = module.function_app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "function_logs_reader" {
  scope                            = module.log_analytics.id
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = module.function_app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "function_subscription_reader" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_name             = "Reader"
  principal_id                     = module.function_app.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "gateway_acr_pull" {
  scope                            = azurerm_container_registry.mcp_gateway.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_container_app.mcp_gateway.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "gateway_monitoring_reader" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_name             = "Monitoring Reader"
  principal_id                     = azurerm_container_app.mcp_gateway.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "gateway_logs_reader" {
  scope                            = module.log_analytics.id
  role_definition_name             = "Log Analytics Reader"
  principal_id                     = azurerm_container_app.mcp_gateway.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "gateway_subscription_reader" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_name             = "Reader"
  principal_id                     = azurerm_container_app.mcp_gateway.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "gateway_search_reader" {
  scope                            = module.ai_search.id
  role_definition_name             = "Search Index Data Reader"
  principal_id                     = azurerm_container_app.mcp_gateway.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

data "azuread_client_config" "current" {}

# data "azuread_service_principal" "github_actions" {
#   client_id = var.github_actions_client_id
# }

# data "azuread_service_principal" "function_app" {
#   object_id = module.function_app.principal_id
# }

# data "azuread_service_principal" "microsoft_graph" {
#   client_id = "00000003-0000-0000-c000-000000000000"
# }

# resource "azuread_application" "mcp_gateway_api" {
#   display_name     = "github"
#   sign_in_audience = "AzureADMyOrg"

#   app_role {
#     allowed_member_types = ["Application"]
#     description          = "Allows the Function App managed identity to invoke MCP Gateway tools."
#     display_name         = "Gateway.Invoke"
#     enabled              = true
#     id                   = "cd84b40d-d82f-4bb3-9a9d-b54c436cc7bd"
#     value                = "Gateway.Invoke"
#   }

#   lifecycle {
#     ignore_changes = [
#       owners,
#       required_resource_access,
#     ]
#   }
# }

# resource "azuread_application_identifier_uri" "mcp_gateway_api" {
#   application_id = azuread_application.mcp_gateway_api.id
#   identifier_uri = local.mcp_gateway_api_audience
# }

# resource "azuread_app_role_assignment" "function_gateway_invoke" {
#   app_role_id         = azuread_application.mcp_gateway_api.app_role_ids["Gateway.Invoke"]
#   principal_object_id = module.function_app.principal_id
#   resource_object_id  = data.azuread_service_principal.github_actions.object_id
# }

# resource "azuread_app_role_assignment" "gateway_graph_permissions" {
#   for_each = toset([
#     "User.Read.All",
#     "Directory.Read.All",
#     "AuditLog.Read.All",
#     "RoleManagement.Read.Directory",
#   ])

#   app_role_id         = data.azuread_service_principal.microsoft_graph.app_role_ids[each.value]
#   principal_object_id = azurerm_container_app.mcp_gateway.identity[0].principal_id
#   resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
# }

# resource "azurerm_role_assignment" "github_acr_push" {
#   scope                            = azurerm_container_registry.mcp_gateway.id
#   role_definition_name             = "AcrPush"
#   principal_id                     = data.azuread_service_principal.github_actions.object_id
#   principal_type                   = "ServicePrincipal"
#   skip_service_principal_aad_check = true
# }

# resource "azurerm_role_assignment" "github_container_app_contributor" {
#   scope                            = azurerm_container_app.mcp_gateway.id
#   role_definition_name             = "Container Apps Contributor"
#   principal_id                     = data.azuread_service_principal.github_actions.object_id
#   principal_type                   = "ServicePrincipal"
#   skip_service_principal_aad_check = true
# }

resource "azapi_resource" "mcp_gateway_auth" {
  type      = "Microsoft.App/containerApps/authConfigs@2024-03-01"
  name      = "current"
  parent_id = azurerm_container_app.mcp_gateway.id

  body = {
    properties = {
      globalValidation = {
        excludedPaths               = ["/health"]
        unauthenticatedClientAction = "Return401"
      }
      httpSettings = {
        requireHttps = true
      }
      identityProviders = {
        azureActiveDirectory = {
          enabled = true
          registration = {
            clientId     = var.github_actions_client_id
            openIdIssuer = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
          }
          validation = {
            allowedAudiences = [local.mcp_gateway_api_audience]
            defaultAuthorizationPolicy = {
              allowedApplications = ["${var.github_actions_client_id}"]
            }
          }
        }
      }
    }
  }

}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "activity-to-log-analytics"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = module.log_analytics.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Policy"
  }

  depends_on = [
    module.log_analytics
  ]
}
