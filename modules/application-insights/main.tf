resource "azurerm_application_insights" "this" {

  name                = "appi-drift-ai-prod"
  location            = var.location
  resource_group_name = var.resource_group_name

  application_type = "web"

  workspace_id = azurerm_log_analytics_workspace.this.id
}