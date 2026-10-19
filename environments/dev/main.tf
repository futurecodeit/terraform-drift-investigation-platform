module "resource_groups" {
  source = "../../modules/resource-group"

  resource_groups = {
    network    = "rg-platform-network-prod"
    security   = "rg-platform-security-prod"
    monitoring = "rg-platform-monitoring-prod"
    ai         = "rg-platform-ai-prod"
    apps       = "rg-platform-apps-prod"
  }

  location = var.location
}

