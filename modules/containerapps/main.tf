resource "azurerm_container_app_environment" "mcp" {
  name                       = "cae-tdip-dev"
  location                   = "UK South"
  resource_group_name        = "rg-tdip-manual-dev"
  log_analytics_workspace_id = "/subscriptions/5e546d2f-02ec-419a-8305-ad234518d98f/resourceGroups/rg-tdip-manual-dev/providers/Microsoft.OperationalInsights/workspaces/law-tdip-manual-dev"
}