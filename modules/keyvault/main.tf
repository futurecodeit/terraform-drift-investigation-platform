resource "azurerm_key_vault" "this" {

  name                = "kvdriftaiprod"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id

  purge_protection_enabled = true
}