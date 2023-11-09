variable "credentials" { default = "account.json" }
variable "project" {}

terraform {

  required_version = ">=0.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=3.46"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.0.1"
    }

  }
}

### Setup GCP provider

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = "us-central1"
}

### Setup a dedicated VPC

resource "google_compute_network" "vpc" {
  name                    = "ubika-waap-vpc"
  auto_create_subnetworks = true
}

### UBIKA WAAP Cloud

# create a network loadbalancer in TCP mode for our URLs
module "lb" {
  source = "../../modules/gcp/lb"

  vpc = google_compute_network.vpc.self_link

  # healthcheck_path = "/"  # set a custom healthcheck path, defaults to a random path

  mapping = [
    # HTTP (port 80) on the public side, must be the same in my tunnel configuration
    {
      name         = "HTTP-my-webapplication"
      proto        = "HTTP"
      port         = 80
      health_check = 80 # HTTP only
    },
    # HTTPS (port 443) on the public side, must be the same in my tunnel configuration
    {
      name         = "HTTPS-my-webapplication"
      proto        = "HTTPS"
      port         = 443
      health_check = 80 # HTTP only
    },
  ]
}

module "ubikawaap" {
  source = "../../modules/gcp/basic"

  vpc = google_compute_network.vpc.self_link # VPC where resources will be created

  target_pools = module.lb.target_pools # load balancer target pools

  additional_management_tags = [] # list of tags to add to management instance for firewall rules
  additional_managed_tags    = [] # list of tags to add to all managed instances for firewall rules

  name_prefix = "my-waf" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAAP administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6-11-5-e9aa5880ea-b46709" # product version to select instance images, changing it will recreate all instances

  management_mode = "byol" # WAAP licence type of the management instance ("payg" or "byol")
  managed_mode    = "byol" # WAAP licence type of the managed instance ("payg" or "byol")

  management_instance_type = "n1-standard-4" # management instance type
  managed_instance_type    = "n1-standard-2" # managed instance type

  nb_managed = 2 # number of managed instances

  management_disk_size = 120 # size of the management disk in GiB (default to 120GiB)
  managed_disk_size    = 30  # size of the managed disk in GiB (default to 30GiB)
}

output "Administration_host" {
  value       = module.ubikawaap.management_public_ip
  description = "Administration access to your WAAP"
}

output "Administration_port" {
  value = "3001"
}

output "Public_URL" {
  value       = module.lb.public_url
  description = "Public acces to your application"
}

output "Healthcheck" {
  value       = module.lb.healthcheck
  description = "Healthcheck URL"
}
