variable "access_key_id" {
}

variable "secret_key_id" {
}

variable "region" {
  default = "eu-west-2"
}

variable "keypair_name" {}

variable "name_prefix" {
  default = "UBIKA WAAP Cloud"
}
terraform {

  required_version = ">=0.14"

  required_providers {
    outscale = {
      source  = "outscale/outscale"
      version = ">=0.12.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.0.1"
    }
  }
}

### Setup AWS provider

provider "outscale" {
  access_key_id = var.access_key_id
  secret_key_id = var.secret_key_id
  region        = var.region
}

### Setup a dedicated VPC
resource "outscale_net" "net" {
  ip_range = "10.0.0.0/16"

  tags {
    key   = "Name"
    value = "${var.name_prefix} Net"
  }
}

resource "outscale_subnet" "subnet" {
  net_id   = outscale_net.net.net_id
  ip_range = "10.0.0.0/18"
  tags {
    key   = "Name"
    value = "${var.name_prefix} Subnet"
  }
}

resource "outscale_internet_service" "internet_service" {
  depends_on = [outscale_net.net]

  tags {
    key   = "Name"
    value = "${var.name_prefix} Internet Service"
  }
}

resource "outscale_internet_service_link" "internet_service_link" {
    internet_service_id = outscale_internet_service.internet_service.internet_service_id
    net_id              = outscale_net.net.net_id
}

resource "outscale_route_table" "route_table" {
  net_id = outscale_net.net.net_id

  tags {
    key   = "Name"
    value = "${var.name_prefix} Route Table"
  }
}

resource "outscale_route" "route" {
  gateway_id           = outscale_internet_service.internet_service.internet_service_id
  destination_ip_range = "0.0.0.0/0"
  route_table_id       = outscale_route_table.route_table.route_table_id
}

resource "outscale_route_table_link" "route_table_link" {
    route_table_id = outscale_route_table.route_table.route_table_id
    subnet_id      = outscale_subnet.subnet.subnet_id
}

### UBIKA WAAP Cloud

# create an AWS ELB in network (TCP) mode for our URL
# here, only one website in HTTP and HTTPS
module "lb" {
  source = "../../modules/outscale/lb"

  net_id     = outscale_net.net.net_id
  subnet_ids = outscale_subnet.subnet.*.id

  managed_ids = module.ubikawaap.managed_ids

  # healthcheck_path = "/" # set a custom healthcheck path, defaults to a random path

  mapping = [
    # HTTP (port 80) on the public side and 1080 in my tunnel configuration
    {
      name  = "HTTP-my-webapplication"
      proto = "HTTP"
      src   = 80
      dest  = 1080
    },
    # HTTPS (port 443) on the public side and 1443 in my tunnel configuration
    {
      name  = "HTTPS-my-webapplication"
      proto = "HTTPS"
      src   = 443
      dest  = 1443
    },
  ]

  lb_name = "mylb" # name prefix in AWS for my AWS ELB objects (must be really short)
}

module "ubikawaap" {
  source = "../../modules/outscale/basic"

  # Outscale net and subnets ids where the WAAP will be deployed
  net_id     = outscale_net.net.net_id
  subnet_ids = outscale_subnet.subnet.*.id

  #target_group_arns      = module.lb.target_group_arns # ARN of the AWS ELB target groups
  additional_managed_sgs = module.lb.security_groups   # list of AWS security groups to add on each managed (require to allow public requests)

  keypair_name = var.keypair_name # Outscale ssh key name for all created instances

  name_prefix = var.name_prefix # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAAP administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6.11.8" # product version to select instance images, changing it will recreate all instances

  management_mode          = "byol"      # WAAP licence type of the management instance ("payg" or "byol")
  management_instance_type = "tinav4.c4r16p2" # management AWS instance type
  management_disk_size     = 120         # size of the management disk in GiB (default to 120GiB)

  managed_mode          = "byol"      # WAAP licence type of the managed instances ("payg" or "byol")
  managed_instance_type = "tinav4.c2r4p2" # managed AWS instance type
  managed_disk_size     = 30          # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 1 # number of managed instances
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

#output "Healthcheck" {
#  value       = module.lb.healthcheck
#  description = "Healthcheck URL"
#}
