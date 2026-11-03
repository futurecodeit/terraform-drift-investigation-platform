terraform {
  backend "azurerm" {
    subscription_id      = "5e546d2f-02ec-419a-8305-ad234518d98f"
    resource_group_name  = "defaultresourcegroup-wus3"
    storage_account_name = "csg100320031401b3a8"
    container_name       = "tfstate"
    key                  = "terraform-drift/dev.tfstate"
    use_azuread_auth     = true
  }
}
