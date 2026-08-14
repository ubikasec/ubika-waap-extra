variable "context" {
  description = ""
}

variable "additional_tags" {
  default = []
}


resource "google_compute_firewall" "management_adm" {
  name        = "management-admin"
  description = "Enable WAAP Administration access"
  network     = var.context.vpc

  direction     = "INGRESS"
  source_ranges = [var.context.admin_location]
  target_tags   = ["ubika-waap-management"]

  allow {
    protocol = "tcp"
    ports    = ["3001", "22"]
  }
}

resource "google_compute_firewall" "management_from_managed" {
  name        = "management-from-managed"
  description = "Enable WAAP Administration access from managed instances for auto-registration"
  network     = var.context.vpc

  direction   = "INGRESS"
  source_tags = ["ubika-waap-managed"]
  target_tags = ["ubika-waap-management"]

  allow {
    protocol = "tcp"
    ports    = ["3001"]
  }
}

# Management instance

resource "google_compute_instance" "management" {
  name         = "${var.context.name_prefix}-management"
  description  = "${var.context.name_prefix} management"
  zone         = var.context.zones[0]
  machine_type = var.context.management_instance_type

  tags = concat(["ubika-waap-management"], var.additional_tags)

  boot_disk {
    initialize_params {
      image = var.context.images.management
      size  = var.context.disk_size.management
    }
  }

  network_interface {
    network = var.context.vpc
    access_config {}
  }

  metadata = {
    user-data = jsonencode({
      instance_role        = "management"
      instance_name        = "management"
      admin_user           = var.context.admin_user
      admin_password       = var.context.admin_pwd
      admin_apiuid         = var.context.admin_apiuid
      admin_multiuser      = true
      enable_autoreg_admin = true
      autoreg_admin_apiuid = var.context.autoreg_admin_apiuid
    })
  }
}

output "private_ip" {
  value = google_compute_instance.management.network_interface.0.network_ip
}

output "public_ip" {
  value = google_compute_instance.management.network_interface.0.access_config.0.nat_ip
}
