resource "azurerm_user_assigned_identity" "function" {

  name                = "mi-drift-api"
  location            = var.location
  resource_group_name = var.resource_group_name
}