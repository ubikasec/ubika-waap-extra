variable "credentials" {
  default = "account.json"
}

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
      health_check = 80
    },
    # HTTPS (port 443) on the public side, must be the same in my tunnel configuration
    {
      name         = "HTTPS-my-webapplication"
      proto        = "HTTPS"
      port         = 443
      health_check = 443
    },
  ]
}

# generate predictable managed instances names
data "google_compute_zones" "zones" {}

module "ubikawaap" {
  source = "../../modules/gcp/autoscaled"

  vpc = google_compute_network.vpc.self_link # VPC where resources will be created

  target_pools = module.lb.target_pools # load balancer target pools

  name_prefix = "my-waf" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAAP administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6-11-13-37e19f1da6-b65713" # product version to select instance images, changing it will recreate all instances

  management_mode            = "byol"          # WAAP licence type of the management instance ("payg" or "byol")
  management_instance_type   = "n1-standard-4" # management instance type
  additional_management_tags = []              # list of tags to add to management instance for firewall rules
  management_disk_size       = 120             # size of the management disk in GiB (default to 120GiB)

  managed_mode            = "byol"          # WAAP licence type of the managed instance ("payg" or "byol")
  managed_instance_type   = "n1-standard-2" # managed instance type
  additional_managed_tags = []              # list of tags to add to all managed instances for firewall rules
  managed_disk_size       = 30              # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 2 # number of managed instances

  autoscaled_product_version = "6-11-13-37e19f1da6-b65713"         # product version to select instance images for autoscaled instances
  autoscaled_instance_type   = "n1-standard-2" # managed instance type
  autoscaled_disk_size       = 20              # size of the autoscaled instances disk in GiB (default to 20GiB)
  additional_autoscaled_tags = []              # list of tags to add to all autoscaled managed instances for firewall rules
  autoscaled_clone_source    = ""              # name of the managed instance that will be cloned by autoscaled instances, (an empty string wil disable the autoscaling part, require on cluster initialization)
}

# add autscaling policy to the autoscaling part of the RS WAAP cluster
module "policy" {
  source = "../../modules/gcp/policy"

  instance_group_manager = module.ubikawaap.instance_group_manager # name of the Instance Group Manager where the policies will be added

  min_size = 0   # minimum number of instances (should be greater that 0)
  max_size = 0   # maximum number of autoscaled instances (0 to disable policy, required on cluster initialization)
  target   = 0.5 # CPU usage of managed instances that will trigger autoscaled instance creation
  cooldown = 300 # time require to start an instance (should be tuned to your configuration)
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
