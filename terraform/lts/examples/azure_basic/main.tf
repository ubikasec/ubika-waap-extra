# Configure the Azure Provider
provider "azurerm" {
  version = "=1.44.0"
}

variable "region" {
  default = "West Europe"
}

variable "name_prefix" {
  default = "RS_WAF_Cloud"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}"
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
  address_prefix       = "10.0.1.0/24"
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

### RS WAF

# create an Azure ELB in network (TCP) mode for our URL
# here, only one website in HTTP and HTTPS
module "lb" {
  source = "../../modules/azure/lb"

  resource_group = azurerm_resource_group.rg
  subnet         = azurerm_subnet.subnet

  mapping = var.lb_mapping
}

module "rswaf" {
  source = "../../modules/azure/basic"

  # Azure resource group and subnets ids where the WAF will be deployed
  resource_group = azurerm_resource_group.rg
  subnet         = azurerm_subnet.subnet
  lb_mapping     = var.lb_mapping

  backend_pool_id = module.lb.backend_pool_id # Backend pool to put the Managed instances into

  ssh_key_data = "ssh-rsa YOUR_SSH_PUBLIC_KEY" # SSH key used for all created instances

  name_prefix = "My WAF Cluster" # a name prefix for resources created by this module

  admin_location = "1.1.1.1/32" # limit access to the WAF administration from this subnet only

  autoreg_admin_apiuid = "6a9f6424ca12dfd25ad4ac82a459e332" # an API key (32 random alphanum chars)

  product_version = "6.5.608" # product version to select instance images, changing it will recreate all instances

  management_mode          = "byol"          # WAF licence type of the management instance ("payg" or "byol")
  management_instance_type = "Standard_B4ms" # management AWS instance type
  management_disk_size     = 120             # size of the management disk in GiB (default to 120GiB)

  managed_mode          = "byol"         # WAF licence type of the managed instances ("payg" or "byol")
  managed_instance_type = "Standard_B2s" # managed AWS instance type
  managed_disk_size     = 30             # size of the managed disk in GiB (default to 30GiB)

  nb_managed = 2 # number of managed instances
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
