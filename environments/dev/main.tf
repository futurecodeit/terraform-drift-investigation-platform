locals {
  resource_group_name  = "rg-${var.name_prefix}-${var.name_suffix}"
  storage_account_name = "st${var.name_prefix}${var.name_suffix}"
  foundry_name         = "fdry${var.name_prefix}${var.name_suffix}"
  search_name          = "srch-${var.name_prefix}-${var.name_suffix}"
  function_name        = "func-${var.name_prefix}-${var.name_suffix}"
  workspace_name       = "law-${var.name_prefix}-${var.name_suffix}"
  insights_name        = "appi-${var.name_prefix}-${var.name_suffix}"
}

module "resource_group" {
  source = "../../modules/resource-group"

  resource_groups = { platform = local.resource_group_name }
  location        = var.location
  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = local.workspace_name
  location            = var.location
  resource_group_name = local.resource_group_name
}

module "application_insights" {
  source = "../../modules/application-insights"

  name                = local.insights_name
  location            = var.location
  resource_group_name = local.resource_group_name
  workspace_id        = module.log_analytics.id
}

module "foundry" {
  source = "../../modules/azure-ai-foundry"

  name              = local.foundry_name
  project_name      = var.foundry_project_name
  location          = var.location
  resource_group_id = module.resource_group.resource_group_ids["platform"]
}

module "ai_search" {
  source = "../../modules/ai-search"

  name                = local.search_name
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = var.ai_search_sku
}

module "function_app" {
  source = "../../modules/function-app"

  name                 = local.function_name
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_name = local.storage_account_name
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
    FOUNDRY_PROJECT_ENDPOINT              = module.foundry.project_endpoint
    FOUNDRY_AGENT_NAME                    = var.foundry_agent_name
    AI_SEARCH_ENDPOINT                    = module.ai_search.endpoint
    AI_SEARCH_INDEX                       = var.ai_search_index
    LOG_ANALYTICS_WORKSPACE_ID            = module.log_analytics.workspace_id
  }
}

resource "azurerm_role_assignment" "foundry_user" {
  scope                = module.foundry.project_id
  role_definition_name = "Foundry User"
  principal_id         = module.function_app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "search_reader" {
  scope                = module.ai_search.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = module.function_app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "logs_reader" {
  scope                = module.log_analytics.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = module.function_app.principal_id
  principal_type       = "ServicePrincipal"
}

data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "tdip-activity-to-log-analytics"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = module.log_analytics.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Policy"
  }
}

