terraform {

  required_version = ">=0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.0.1"
    }

  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

variable "region" {
  default = "West Europe"
}

variable "name_prefix" {
  default = "UBIKA_WAAP_Cloud_Autoscaled"
}

resource "azurerm_resource_group" "rg" {
  name     = var.name_prefix
  location = var.region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

variable "lb_mapping" {
  default = [
    # HTTP (port 80) on the public side and 1080 in my tunnel configuration
    {
      name  = "HTTP-my-webapplication"
      proto = "Http"
      src   = 80
      dest  = 1080
    },
    # HTTPS (port 443) on the public side and 1443 in my tunnel configuration
    {
      name  = "HTTPS-my-webapplication"
      proto = "Https"
      src   = 443
      dest  = 1443
    },
  ]
}

### UBIKA WAAP Cloud

# create an Azure ELB in network (TCP) mode for our URL
# here, only one website in HTTP and HTTPS
module "lb" {
  source = "../../modules/azure/lb"

  resource_group = azurerm_resource_group.rg
  subnet         = azurerm_subnet.subnet

  # healthcheck_path = "/" # set a custom healthcheck path, defaults to a random path

  mapping = var.lb_mapping
}

module "ubikawaap" {
  source = "../../modules/azure/autoscaled"

  # Azure resource group and subnets ids where the WAAP will be deployed
  resource_group = azurerm_resource_group.rg
  subnet         = azurerm_subnet.subnet
  lb_mapping     = var.lb_mapping

  backend_pool_id = module.lb.backend_pool_id # Backend pool to put the Managed instances into

  ssh_key_data = "ssh-rsa YOUR_SSH_PUBLIC_KEY" # SSH key used for all created instances

  name_prefix = "My WAAP Cluster" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAAP administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6.11.4" # product version to select instance images, changing it will recreate all instances

  management_mode          = "byol"          # WAAP licence type of the management instance ("payg" or "byol")
  management_instance_type = "Standard_B4ms" # management AWS instance type
  management_disk_size     = 120             # size of the management disk in GiB (default to 120GiB)

  managed_mode          = "byol"         # WAAP licence type of the managed instances ("payg" or "byol")
  managed_instance_type = "Standard_B2s" # managed AWS instance type
  managed_disk_size     = 30             # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 2 # number of managed instances

  # autoscaled instances will be in payg mode
  autoscaled_disk_size    = 15          # size of the autoscaled instances disk in GiB (default to 15GiB)
  autoscaled_clone_source = "managed_0" # name of the managed instance that will be cloned by autoscaled instances

  autoscaler_current_size = 1 # current or initial number of autoscaled instances
}

# add autscaling policy to the autoscaling part of the RS WAAP cluster
module "policy" {
  source = "../../modules/azure/policy"

  prefix = "ubikawaap" # name prefix for resources created by this module

  resource_group = azurerm_resource_group.rg

  # UBIKA WAAP Cloud cluster informations
  scale_set_id = module.ubikawaap.scale_set_id # id of the scale set where the policies will be added
  managed_ids  = module.ubikawaap.managed_ids  # ids of the managed instances

  autoscaler_min_size = 0  # minimum number of autoscaled instances (should be 0)
  autoscaler_max_size = 10 # maximum number of autoscaled instances

  target             = 40      # CPU usage of managed instances that will trigger autoscaled instance creation
  scale_out_cooldown = "PT5M"  # the amount of time to wait since the last scaling up action before a next action occurs(should be tuned to your configuration)
  scale_in_cooldown  = "PT30M" # the amount of time to wait since the last scaling down action before a next action occurs(should be tuned to your configuration)
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
