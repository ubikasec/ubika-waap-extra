variable "credentials" { default = "account.json" }
variable "project" {}


### Setup GCP provider

provider "google" {
  credentials = "${file(var.credentials)}"
  project     = var.project
  region      = "us-central1"
  version     = "= 3.46"
}

### Setup a dedicated VPC

resource "google_compute_network" "vpc" {
  name                    = "rswaf-vpc"
  auto_create_subnetworks = true
}

### RS WAF

# create a network loadbalancer in TCP mode for our URLs
module "lb" {
  source = "../../modules/gcp/lb"

  vpc = google_compute_network.vpc.self_link

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

module "rswaf" {
  source = "../../modules/gcp/basic"

  vpc = google_compute_network.vpc.self_link # VPC where resources will be created

  target_pools = module.lb.target_pools # load balancer target pools

  additional_management_tags = [] # list of tags to add to management instance for firewall rules
  additional_managed_tags    = [] # list of tags to add to all managed instances for firewall rules

  name_prefix = "my-waf" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAF administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6-5-6-patch2-f767e70-b16507" # product version to select instance images, changing it will recreate all instances

  management_mode = "byol" # WAF licence type of the management instance ("payg" or "byol")
  managed_mode    = "byol" # WAF licence type of the managed instance ("payg" or "byol")

  management_instance_type = "n1-standard-4" # management instance type
  managed_instance_type    = "n1-standard-2" # managed instance type

  nb_managed = 2 # number of managed instances

  management_disk_size = 120 # size of the management disk in GiB (default to 120GiB)
  managed_disk_size    = 30  # size of the managed disk in GiB (default to 30GiB)
}

output "Administration_host" {
  value       = module.rswaf.management_public_ip
  description = "Administration access to your WAF"
}

output "Administration_port" {
  value = "3001"
}

output "Public_URL" {
  value       = module.lb.public_url
  description = "Public acces to your application"
}
