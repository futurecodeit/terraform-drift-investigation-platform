resource "azurerm_linux_function_app" "this" {

  name                = "func-drift-investigator-prod"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_name       = azurerm_storage_account.app.name
  storage_account_access_key = azurerm_storage_account.app.primary_access_key

  service_plan_id = azurerm_service_plan.this.id

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.function.id
    ]
  }

  site_config {
    application_stack {
      python_version = "3.12"
    }
  }
}