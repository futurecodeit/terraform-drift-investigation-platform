resource "azurerm_virtual_network" "this" {

  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = [
    "10.100.0.0/16"
  ]
}

resource "azurerm_subnet" "function" {

  name                 = "snet-function"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [
    "10.100.1.0/24"
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
    "10.100.2.0/24"
  ]
}

resource "azurerm_subnet" "private_endpoints" {

  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [
    "10.100.3.0/24"
  ]
}