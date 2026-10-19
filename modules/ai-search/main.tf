resource "azurerm_search_service" "this" {

  name                = "aisearchdriftprod"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku = "standard"
}