variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used by the AzureRM provider."
}

variable "location" {
  type        = string
  description = "Azure region for the platform resources."
  default     = "eastus2"
}

variable "name_prefix" {
  type        = string
  description = "Short lowercase name prefix used for resource names."
  default     = "tdip"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.name_prefix))
    error_message = "name_prefix must contain 2-8 lowercase letters or digits."
  }
}

variable "name_suffix" {
  type        = string
  description = "4-8 lowercase alphanumeric characters that make globally unique names."

  validation {
    condition     = can(regex("^[a-z0-9]{4,8}$", var.name_suffix))
    error_message = "name_suffix must contain 4-8 lowercase letters or digits."
  }
}

variable "foundry_project_name" {
  type        = string
  description = "Microsoft Foundry project name created under the Foundry resource."
  default     = "drift-investigation"
}

variable "foundry_agent_name" {
  type        = string
  description = "Versioned Microsoft Foundry prompt agent invoked by the Function App."
  default     = "terraform-drift-investigator"
}

variable "ai_search_index" {
  type        = string
  description = "Azure AI Search index created by scripts/index_documents.py."
  default     = "platform-knowledge"
}

variable "ai_search_sku" {
  type        = string
  description = "Azure AI Search SKU. Basic is suitable for development; select production capacity separately."
  default     = "basic"
}
