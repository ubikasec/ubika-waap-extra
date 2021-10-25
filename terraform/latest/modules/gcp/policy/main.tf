variable "instance_group_manager" {}

variable "prefix" { default = "rswaf" }

variable "target" { default = 0.7 }

variable "min_size" { default = 0 }
variable "max_size" { default = 0 }

variable "cooldown" { default = 300 }

resource "google_compute_region_autoscaler" "autoscaler" {
  count    = var.max_size == 0 ? 0 : 1
  provider = google
  name     = "${var.prefix}-autoscaler"
  target   = var.instance_group_manager

  autoscaling_policy {
    max_replicas    = var.max_size
    min_replicas    = var.min_size
    cooldown_period = var.cooldown

    cpu_utilization {
      target = var.target
    }
  }
}
