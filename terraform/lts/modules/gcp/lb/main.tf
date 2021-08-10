variable "vpc" {
  description = ""
}

variable "instances_names" {
  description = ""
  default     = []
}

variable "mapping" {
}

# load balancer

resource "google_compute_http_health_check" "health-check" {
  count = length(var.mapping)
  name  = "health-check-${count.index}"

  timeout_sec         = 1
  check_interval_sec  = 10
  healthy_threshold   = 3
  unhealthy_threshold = 3

  port = var.mapping[count.index].health_check
}

resource "google_compute_target_pool" "target_pool" {
  count         = length(var.mapping)
  name          = "target-pool-${count.index}"
  health_checks = [google_compute_http_health_check.health-check[count.index].self_link]
}

resource "google_compute_address" "lb_address" {
  name = "lb-ipv4-address"
}

resource "google_compute_forwarding_rule" "lb" {
  count      = length(var.mapping)
  name       = "lb-${count.index}"
  ip_address = google_compute_address.lb_address.address
  port_range = var.mapping[count.index].port
  target     = google_compute_target_pool.target_pool[count.index].self_link
}

data "google_compute_lb_ip_ranges" "ranges" {}

resource "google_compute_firewall" "lb" {
  name    = "lb-firewall"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = var.mapping.*.port
  }

  source_ranges = data.google_compute_lb_ip_ranges.ranges.network
  target_tags = [
    "rswaf-managed"
  ]
}

resource "google_compute_firewall" "web_input" {
  name    = "web-input"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = var.mapping.*.port
  }

  target_tags = [
    "rswaf-managed"
  ]
}

output "target_pools" {
  value = google_compute_target_pool.target_pool.*.self_link
}

output "public_url" {
  value       = "http://${google_compute_address.lb_address.address}/"
  description = "Public acces to your application"
}
