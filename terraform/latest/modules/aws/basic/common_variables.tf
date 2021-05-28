variable "vpc_id" {}
variable "subnet_ids" {}
variable "target_group_arns" {}

variable "key_name" {}

# RSWAF Settings

variable "product_version" { default = "" }

variable "name_prefix" {
  default = "rswaf-cloud"
}

variable "cluster_name" { default = "" }

variable "admin_location" {
  description = "The IP address range that can be used to administrate the WAF instances"
  default     = "0.0.0.0/0"
}

variable "admin_user" { default = "admin" }
variable "admin_pwd" { default = "" }
variable "admin_apiuid" { default = "" }

variable "autoreg_admin_user" { default = "autoreg_admin" }
variable "autoreg_admin_apiuid" { default = "" }

variable "aws_cloudwatch_monitoring" { default = "false" }

# Management instance
variable "management_mode" {
  description = "Enter management instance license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "management_instance_type" { default = "t2.xlarge" }
variable "additional_management_sgs" { default = [] }
variable "management_disk_size" { default = 120 }

# Managed instances
variable "managed_mode" {
  description = "Enter managed instance license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "managed_instance_type" { default = "t2.medium" }
variable "additional_managed_sgs" { default = [] }
variable "managed_disk_size" { default = 30 }

variable "nb_managed" { default = "0" }
