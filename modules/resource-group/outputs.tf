output "resource_group_ids" {
  value = { for key, group in azurerm_resource_group.rg : key => group.id }
}

output "resource_group_names" {
  value = { for key, group in azurerm_resource_group.rg : key => group.name }
}