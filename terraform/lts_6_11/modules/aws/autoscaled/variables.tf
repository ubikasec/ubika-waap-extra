# Autoscaled instances
variable "autoscaled_mode" {
  description = "Enter autoscaled instances license mode \"Bring Your Own License\" or \"PAYG\". Default is \"byol\"."
  default     = "byol"
}
variable "autoscaled_instance_type" { default = "t2.medium" }
variable "autoscaled_product_version" { default = "" }
variable "additional_autoscaled_tags" { default = [] }
variable "autoscaled_disk_size" { default = 15 }

variable "autoscaled_clone_source" { default = "managed_0" }

# Autoscaler
variable "autoscaler_min_size" {
  default = 0
}
variable "autoscaler_max_size" {
  default = 0
}
variable "autoscaler_default_cooldown" {
  default = 300
}
variable "autoscaler_health_check_type" {
  default = "EC2"
}
variable "autoscaler_health_check_grace_period" {
  default = 300
}
variable "autoscaler_termination_policies" {
  default = ["Default"]
}
