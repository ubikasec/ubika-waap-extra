variable "context" {}
variable "management_private_ip" {}
variable "additional_tags" { default = [] }

resource "google_compute_firewall" "managed_from_management" {
  name        = "managed-from-management"
  description = "Enable WAAP Administration access from the Management instance"
  network     = var.context.vpc

  direction   = "INGRESS"
  source_tags = ["ubika-waap-management"]
  target_tags = ["ubika-waap-managed"]

  allow {
    protocol = "tcp"
    ports    = ["2222", "3001", "48400", "22"]
  }
}
resource "google_compute_firewall" "managed_admin" {
  name        = "managed-admin"
  description = "Enable WAAP Administration access from the admin_location"
  network     = var.context.vpc

  direction     = "INGRESS"
  source_ranges = [var.context.admin_location]
  target_tags   = ["ubika-waap-managed"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}


# Managed instances
resource "google_compute_region_instance_group_manager" "managed" {
  name = "${var.context.name_prefix}-managed"

  base_instance_name        = "${var.context.name_prefix}-managed"
  region                    = var.context.region
  distribution_policy_zones = var.context.zones

  target_pools = var.context.target_pools
  target_size  = var.context.nb_managed

  version {
    name              = "main"
    instance_template = google_compute_instance_template.managed.self_link
  }


  update_policy {
    type                         = "OPPORTUNISTIC"
    instance_redistribution_type = "NONE"
    minimal_action               = "RESTART"
    max_unavailable_fixed        = length(var.context.zones)
  }
}

resource "google_compute_instance_template" "managed" {
  name_prefix = "${var.context.name_prefix}-managed-template"

  instance_description = "${var.context.name_prefix} managed"
  machine_type         = var.context.managed_instance_type

  tags = concat(["ubika-waap-managed"], var.additional_tags)

  disk {
    boot         = true
    source_image = var.context.images.managed
    disk_size_gb = var.context.disk_size.managed
  }

  network_interface {
    network = var.context.vpc
    access_config {}
  }

  metadata = {
    user-data = jsonencode({
      instance_role = "managed"
      instance_name = "managed-##"
      linkto_ip     = var.management_private_ip
      linkto_port   = "3001"
      linkto_apikey = var.context.autoreg_admin_apikey
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "template" { value = google_compute_instance_template.managed }
