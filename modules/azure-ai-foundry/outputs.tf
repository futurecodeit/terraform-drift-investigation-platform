output "account_id" {
  value = azapi_resource.account.id
}

output "project_id" {
  value = azapi_resource.project.id
}
output "project_endpoint" {
  value = "https://${var.name}.services.ai.azure.com/api/projects/${var.project_name}"
}