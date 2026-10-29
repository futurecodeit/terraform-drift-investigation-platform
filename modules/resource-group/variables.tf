variable "location" {
  type = string
}

variable "resource_groups" {
  type = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
