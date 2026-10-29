resource "azurerm_virtual_network" "this" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = var.address_space
}

resource "azurerm_subnet" "function" {

  name                 = "snet-function"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [
    var.function_subnet_prefix
  ]

  delegation {
    name = "function"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "foundry" {

  name                 = "snet-foundry"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [
    var.foundry_subnet_prefix
  ]
}

resource "azurerm_subnet" "private_endpoints" {

  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [
    var.private_endpoints_subnet_prefix
  ]
}