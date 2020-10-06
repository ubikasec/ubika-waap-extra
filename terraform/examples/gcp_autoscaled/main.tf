variable "credentials" {
  default = "account.json"
}

variable "project" {}

### Setup GCP provider

provider "google" {
  credentials = "${file(var.credentials)}"
  project     = var.project
  region      = "us-central1"
  version     = "= 2.19"
}
provider "google-beta" {
  credentials = "${file(var.credentials)}"
  project     = var.project
  region      = "us-central1"
  version     = "= 2.19"
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
      port         = 1080
      health_check = 1080 # HTTP only
    },
    # HTTPS (port 443) on the public side, must be the same in my tunnel configuration
    {
      name         = "HTTPS-my-webapplication"
      proto        = "HTTPS"
      port         = 1443
      health_check = 1080 # HTTP only
    },
  ]
}

# generate predictable managed instances names
data "google_compute_zones" "zones" {}

module "rswaf" {
  source = "../../modules/gcp/autoscaled"

  vpc = google_compute_network.vpc.self_link # VPC where resources will be created

  target_pools = module.lb.target_pools # load balancer target pools

  name_prefix = "my-waf" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAF administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6-5-6-patch2-f767e70-b16507" # product version to select instance images, changing it will recreate all instances

  management_mode            = "byol"          # WAF licence type of the management instance ("payg" or "byol")
  management_instance_type   = "n1-standard-4" # management instance type
  additional_management_tags = []              # list of tags to add to management instance for firewall rules
  management_disk_size       = 120             # size of the management disk in GiB (default to 120GiB)

  managed_mode            = "byol"          # WAF licence type of the managed instance ("payg" or "byol")
  managed_instance_type   = "n1-standard-2" # managed instance type
  additional_managed_tags = []              # list of tags to add to all managed instances for firewall rules
  managed_disk_size       = 30              # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 2 # number of managed instances

  autoscaled_product_version = "6.5.5"         # product version to select instance images for autoscaled instances
  autoscaled_instance_type   = "n1-standard-2" # managed instance type
  autoscaled_disk_size       = 15              # size of the autoscaled instances disk in GiB (default to 15GiB)
  additional_autoscaled_tags = []              # list of tags to add to all autoscaled managed instances for firewall rules
  autoscaled_clone_source    = ""              # name of the managed instance that will be cloned by autoscaled instances, (an empty string wil disable the autoscaling part, require on cluster initialization)
}

# add autscaling policy to the autoscaling part of the RS WAF cluster
module "policy" {
  source = "../../modules/gcp/policy"

  instance_group_manager = module.rswaf.instance_group_manager # name of the Instance Group Manager where the policies will be added

  min_size = 0   # minimum number of instances (should be greater that 0)
  max_size = 0   # maximum number of autoscaled instances (0 to disable policy, required on cluster initialization)
  target   = 0.5 # CPU usage of managed instances that will trigger autoscaled instance creation
  cooldown = 300 # time require to start an instance (should be tuned to your configuration)
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
