# Azure common

variable "resource_group" {}
variable "subnet" {}
variable "backend_pool_id" {}
variable "ssh_key_data" {}
variable "lb_mapping" {}

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
variable "management_instance_type" { default = "Standard_B4ms" }
variable "additional_management_sgs" { default = [] }
variable "management_disk_size" { default = 120 }

# Managed instances
variable "managed_mode" {
  description = "Enter managed instance license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "managed_instance_type" { default = "Standard_B2s" }
variable "additional_managed_sgs" { default = [] }
variable "managed_disk_size" { default = 30 }

variable "nb_managed" { default = "0" }
