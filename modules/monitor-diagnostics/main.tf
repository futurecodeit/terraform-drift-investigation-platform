resource "azurerm_monitor_diagnostic_setting" "activity" {

  name = "activity-logs"

  target_resource_id = var.subscription_resource_id

  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Security"
  }
}