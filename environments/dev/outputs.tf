output "resource_group_name" {
  value = module.resource_group.resource_group_names["platform"]
}

output "function_app_name" {
  value = module.function_app.name
}

output "function_app_url" {
  value = "https://${module.function_app.default_hostname}/api/investigate"
}

output "function_app_principal_id" {
  value = module.function_app.principal_id
}

output "function_subnet_id" {
  value = module.virtual_network.function_subnet_id
}

output "container_apps_subnet_id" {
  value = module.virtual_network.container_apps_subnet_id
}

output "container_apps_environment_id" {
  value = azurerm_container_app_environment.mcp_gateway.id
}

output "container_apps_environment_name" {
  value = azurerm_container_app_environment.mcp_gateway.name
}

output "mcp_gateway_url" {
  value = "https://${azurerm_container_app.mcp_gateway.ingress[0].fqdn}"
}

output "mcp_gateway_container_app_name" {
  value = azurerm_container_app.mcp_gateway.name
}

output "mcp_gateway_acr_name" {
  value = azurerm_container_registry.mcp_gateway.name
}

output "mcp_gateway_acr_login_server" {
  value = azurerm_container_registry.mcp_gateway.login_server
}

output "foundry_project_endpoint" {
  value = module.foundry.project_endpoint
}

output "ai_search_endpoint" {
  value = module.ai_search.endpoint
}

output "ai_search_service_id" {
  value = module.ai_search.id
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.workspace_id
}

output "log_analytics_resource_id" {
  value = module.log_analytics.id
}
