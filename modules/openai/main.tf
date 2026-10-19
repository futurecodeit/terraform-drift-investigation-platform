resource "azurerm_cognitive_account" "openai" {

  name                = "aoaidriftprod"
  resource_group_name = var.resource_group_name

  location = var.location

  kind = "OpenAI"

  sku_name = "S0"
}