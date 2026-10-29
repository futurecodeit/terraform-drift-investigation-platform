output "id" {
  value = azurerm_virtual_network.this.id
}

output "function_subnet_id" {
  value = azurerm_subnet.function.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}