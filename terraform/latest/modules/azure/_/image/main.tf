variable "product_version" { default = "6.13.0" }

variable "management_mode" {}
variable "managed_mode" {}
variable "autoscaled_mode" { default = "" }

locals {
  publisher     = "ubika"
  offer         = "ubika-waap-cloud"
  image_version = replace(var.product_version, "/-.*$/", "")
  skus = {
    byol = "6-latest-byol"
    payg = "6-latest-payg"
  }
  ids = {
    byol = ""
    payg = ""
  }
}

resource "azurerm_marketplace_agreement" "waf_byol" {
  publisher = local.publisher
  offer     = local.offer
  plan      = "byol"
}
resource "azurerm_marketplace_agreement" "waf_payg" {
  publisher = local.publisher
  offer     = local.offer
  plan      = "hourly"
}

output "publisher" {
  value = local.publisher
}
output "offer" {
  value = local.offer
}
output "version" {
  value = local.image_version
}
output "management" {
  value = var.management_mode == "payg" ? local.skus.payg : local.skus.byol
}
output "managed" {
  value = var.managed_mode == "payg" ? local.skus.payg : local.skus.byol
}
output "autoscaled" {
  value = var.autoscaled_mode == "byol" ? local.skus.byol : local.skus.payg
}
output "id_management" {
  value = var.management_mode == "byol" ? local.ids.byol : local.ids.payg
}
output "id_managed" {
  value = var.managed_mode == "byol" ? local.ids.byol : local.ids.payg
}
output "id_autoscaled" {
  value = var.autoscaled_mode == "byol" ? local.ids.byol : local.ids.payg
}
