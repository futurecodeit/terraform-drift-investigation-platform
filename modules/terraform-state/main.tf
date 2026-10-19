resource "azurerm_storage_account" "tfstate" {

  name                     = "stterraformstateprod"
  resource_group_name      = var.resource_group_name
  location                 = var.location

  account_tier             = "Standard"
  account_replication_type = "ZRS"

  versioning_enabled = true
}

resource "azurerm_storage_container" "tfstate" {

  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}