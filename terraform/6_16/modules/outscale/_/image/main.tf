terraform {
  required_providers {
    outscale = {
      source = "outscale/outscale"
      version = "0.12.0"
    }
  }
}

variable "product_version" {}

variable "management_mode" {}
variable "managed_mode" {}

locals {
  image_version = replace(var.product_version, ".", "-")
}

data "outscale_image" "byol" {
  filter {
    name   = "image_names"
    values = ["UBIKA-WAAP-byol-${local.image_version}-MKP*"]
  }
}

data "outscale_image" "payg" {
  filter {
    name   = "image_names"
    values = ["UBIKA-WAAP-payg-${local.image_version}-MKP*"]
  }
}

output "management" {
  value = var.management_mode == "payg" ? data.outscale_image.payg.id : data.outscale_image.byol.id
}
output "managed" {
  value = var.managed_mode == "payg" ? data.outscale_image.payg.id : data.outscale_image.byol.id
}
