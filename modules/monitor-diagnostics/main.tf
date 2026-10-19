resource "azurerm_monitor_diagnostic_setting" "activity" {

  name = "activity-logs"

  target_resource_id = data.azurerm_subscription.current.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

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