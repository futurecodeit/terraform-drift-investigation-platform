variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}
variable "address_space" {
  type    = list(string)
  default = ["10.100.0.0/16"]
}
variable "function_subnet_prefix" {
  type    = string
  default = "10.100.1.0/24"
}
variable "foundry_subnet_prefix" {
  type    = string
  default = "10.100.2.0/24"
}
variable "private_endpoints_subnet_prefix" {
  type    = string
  default = "10.100.3.0/24"
}
variable "container_apps_subnet_prefix" {
  type        = string
  description = "Dedicated subnet for the private Container Apps environment. Workload profiles require at least /27."
  default     = "10.100.4.0/27"
}