variable "access_key" {
}

variable "secret_key" {
}

variable "region" {
  default = "us-east-1"
}

variable "name_prefix" {
  default = "UBIKA WAAP Cloud"
}

terraform {

  required_version = ">=0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=2.26"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.0.1"
    }

  }
}

### Setup AWS provider

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

### Setup a dedicated VPC

# get all available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.name_prefix} VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name_prefix} Internet Gateway"
  }
}

# create a subnet per availability zone
resource "aws_subnet" "subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, length(data.aws_availability_zones.available.names), count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix} Subnet for ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.name_prefix} Route Table"
  }
}

resource "aws_route_table_association" "rta" {
  count          = length(aws_subnet.subnet.*.id)
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.route_table.id
}

### UBIKA WAAP Cloud

# create an AWS ELB in network (TCP) mode for our URL
# here, only one website in HTTP and HTTPS
module "lb" {
  source = "../../modules/aws/lb"

  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.subnet.*.id

  # healthcheck_path = "/" # set a custom healthcheck path, defaults to a random path

  mapping = [
    # HTTP (port 80) on the public side and 80 in my tunnel configuration
    {
      name  = "HTTP-my-webapplication"
      proto = "HTTP"
      src   = 80
      dest  = 80
    },
    # HTTPS (port 443) on the public side and 443 in my tunnel configuration
    {
      name  = "HTTPS-my-webapplication"
      proto = "HTTPS"
      src   = 443
      dest  = 443
    },
  ]

  lb_name                    = "mylb" # name prefix in AWS for my AWS ELB objects (must be really short)
  enable_deletion_protection = true   # protect this AWS ELB from accidental deletion
}

module "ubikawaap" {
  source = "../../modules/aws/autoscaled"

  # AWS VPC and subnets ids where the WAAP will be deployed
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.subnet.*.id

  target_group_arns      = module.lb.target_group_arns # ARN of the AWS ELB target groups
  additional_managed_sgs = module.lb.security_groups   # list of AWS security groups to add on each managed (require to allow public requests)

  key_name = "mykey" # AWS ssh key name for all created instances

  name_prefix = "My WAAP Cluster" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAAP administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  aws_cloudwatch_monitoring = false # Enable AWS Cloudwatch agent metrics.

  product_version = "6.11.8" # product version to select instance images, changing it will recreate all instances

  management_mode          = "byol"      # WAAP licence type of the management instance ("payg" or "byol")
  management_instance_type = "m5.xlarge" # management AWS instance type
  management_disk_size     = 120         # size of the management disk in GiB (default to 120GiB)

  managed_mode          = "byol"      # WAAP licence type of the managed instances ("payg" or "byol")
  managed_instance_type = "t2.medium" # managed AWS instance type
  managed_disk_size     = 30          # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 2 # number of managed instances

  autoscaled_disk_size    = 15          # size of the autoscaled instances disk in GiB (default to 15GiB)
  autoscaled_clone_source = "managed_0" # name of the managed instance that will be cloned by autoscaled instances

  autoscaler_min_size = 0  # minimum number of autoscaled instances (should be 0)
  autoscaler_max_size = 10 # maximum number of autoscaled instances
}

# add autscaling policy to the autoscaling part of the RS WAAP cluster
module "policy" {
  source = "../../modules/aws/policy"

  prefix = "ubikawaap" # name prefix for resources created by this module (must be really short)

  # UBIKA WAAP Cloud cluster informations
  autoscaling_group_name = module.ubikawaap.autoscaling_group_name # name of the AWS AutoScalingGroup where the policies will be added
  managed_ids            = module.ubikawaap.managed_ids            # ids of the managed instances

  target                    = 50    # CPU usage of managed instances that will trigger autoscaled instance creation
  estimated_instance_warmup = 300   # time require to start an instance (should be tuned to your configuration)
  disable_scale_in          = false # if set to "true" instance will not be deleted when load goes down
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
