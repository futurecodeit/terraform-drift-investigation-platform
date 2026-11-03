variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "virtual_network_subnet_id" {
  type        = string
  description = "Delegated subnet used for regional VNet integration."
}

variable "app_settings" {
  type      = map(string)
  sensitive = true
  default   = {}
}