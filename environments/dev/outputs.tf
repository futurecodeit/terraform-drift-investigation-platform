output "resource_group_name" {
  value = module.resource_group.resource_group_names["platform"]
}

output "function_app_name" {
  value = module.function_app.name
}

output "function_app_url" {
  value = "https://${module.function_app.default_hostname}/api/investigate"
}

output "foundry_project_endpoint" {
  value = module.foundry.project_endpoint
}

output "ai_search_endpoint" {
  value = module.ai_search.endpoint
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.workspace_id
}
