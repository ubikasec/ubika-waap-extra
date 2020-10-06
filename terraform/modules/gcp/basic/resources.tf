# locals

locals {
  autoreg_admin_apikey = "${base64encode(var.autoreg_admin_user)}@${var.autoreg_admin_apiuid}"
}

### GCP resources

data "google_compute_zones" "zones" {}
data "google_client_config" "current" {}

module "images" {
  source = "../_/images"

  management_mode = var.management_mode
  managed_mode    = var.managed_mode

  product_version = var.product_version
}

module "management" {
  source = "../_/management"

  context         = local.context
  additional_tags = []
}

module "managed" {
  source = "../_/managed"

  context               = local.context
  additional_tags       = []
  management_private_ip = module.management.private_ip
}

# Outputs

output "management_public_ip" {
  value = module.management.public_ip
}
output "management_private_ip" {
  value = module.management.private_ip
}
