# GCP common

variable "vpc" {}
variable "region" { default = "" }
variable "zones" { default = [] }
variable "target_pools" {}

# WAAP Settings

variable "product_version" { default = "" }

variable "name_prefix" {
  default = "ubika-waap-cloud"
}

variable "cluster_name" { default = "" }

variable "admin_location" {
  description = "The IP address range that can be used to administrate the WAAP instances"
  default     = "0.0.0.0/0"
}

variable "admin_user" { default = "admin" }
variable "admin_pwd" { default = "" }
variable "admin_apiuid" { default = "" }

variable "autoreg_admin_user" { default = "autoreg_admin" }
variable "autoreg_admin_apiuid" { default = "" }

# Management instance
variable "management_mode" {
  description = "Enter management instance license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "management_instance_type" { default = "n1-standard-4" }
variable "additional_management_tags" { default = [] }
variable "management_disk_size" { default = 120 }

# Managed instances
variable "managed_mode" {
  description = "Enter managed instance license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "managed_instance_type" { default = "n1-standard-2" }
variable "additional_managed_tags" { default = [] }
variable "managed_disk_size" { default = 30 }

variable "nb_managed" { default = "0" }
