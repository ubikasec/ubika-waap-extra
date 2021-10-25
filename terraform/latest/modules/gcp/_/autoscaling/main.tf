variable "context" {
  description = ""
}

variable "management_private_ip" {}
variable "autoscaled_clone_source" {}
variable "managed_template" {}

variable "additional_tags" {
  default = []
}

# On demand managed instances
resource "google_compute_region_instance_group_manager" "autoscaled" {
  count = var.autoscaled_clone_source == "" ? 0 : 1
  name  = "${var.context.name_prefix}-autoscaled"

  base_instance_name        = "${var.context.name_prefix}-autoscaled"
  region                    = var.context.region
  distribution_policy_zones = var.context.zones

  target_pools = var.context.target_pools

  version {
    name              = "autoscaled"
    instance_template = google_compute_instance_template.autoscaled.self_link
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = length(var.context.zones)
  }
}

resource "google_compute_instance_template" "autoscaled" {
  name_prefix = "${var.context.name_prefix}-autoscaled-template"

  instance_description = "${var.context.name_prefix} autoscaled managed"
  machine_type         = var.context.autoscaled_instance_type

  tags = concat(["rswaf-managed", "rswaf-autoscaled"], var.additional_tags)

  disk {
    boot         = true
    source_image = var.context.images.autoscaled
    disk_size_gb = var.context.disk_size.autoscaled
  }

  network_interface {
    network = var.context.vpc
    access_config {}
  }

  metadata = {
    user-data = jsonencode({
      instance_role = "managed"
      instance_name = "autoscaled-managed-"
      autoscale     = "true"
      cloneof_name  = var.autoscaled_clone_source
      linkto_ip     = var.management_private_ip
      linkto_port   = "3001"
      linkto_apikey = var.context.autoreg_admin_apikey
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_group_manager" {
  value = length(google_compute_region_instance_group_manager.autoscaled) > 0 ? google_compute_region_instance_group_manager.autoscaled[0].self_link : ""
}
