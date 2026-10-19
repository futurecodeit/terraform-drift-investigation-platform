resource "azurerm_resource_group" "rg" {

  for_each = var.resource_groups

  name     = each.value
  location = var.location
}