resource "azurerm_key_vault" "this" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id

  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = var.public_network_access_enabled
}

data "azurerm_client_config" "current" {}