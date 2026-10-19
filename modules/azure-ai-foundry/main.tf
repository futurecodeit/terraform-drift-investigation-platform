resource "azurerm_cognitive_deployment" "gpt4o" {

  name = "gpt-4o"

  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "latest"
  }

  sku {
    name     = "Standard"
    capacity = 100
  }
}