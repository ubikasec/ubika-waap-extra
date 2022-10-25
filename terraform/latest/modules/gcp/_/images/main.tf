variable "product_version" {}

variable "management_mode" { default = "" }
variable "managed_mode" { default = "" }
variable "autoscaled_mode" { default = "" }

data "google_compute_image" "byol" {
  name    = "ubika-waap-latest-byol-${var.product_version}"
  project = "rohde-schwarz-cs-sas-public"
}

data "google_compute_image" "payg" {
  name    = "ubika-waap-latest-payg-${var.product_version}"
  project = "rohde-schwarz-cs-sas-public"
}


output "management" {
  value = var.management_mode == "payg" ? data.google_compute_image.payg.self_link : data.google_compute_image.byol.self_link
}
output "managed" {
  value = var.managed_mode == "payg" ? data.google_compute_image.payg.self_link : data.google_compute_image.byol.self_link
}
output "autoscaled" {
  value = var.autoscaled_mode == "byol" ? data.google_compute_image.byol.self_link : data.google_compute_image.payg.self_link
}
