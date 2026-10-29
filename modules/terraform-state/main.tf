resource "azurerm_storage_account" "tfstate" {

  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "ZRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    container_delete_retention_policy {
      days = 7
    }

    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "tfstate" {

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}