module "image" {
  source = "../_/image"

  management_mode = var.management_mode
  managed_mode    = var.managed_mode

  product_version = var.product_version
}

# locals

locals {
  autoreg_admin_apikey = "${base64encode(var.autoreg_admin_user)}@${var.autoreg_admin_apiuid}"
}

# Application Security Groups

resource "azurerm_application_security_group" "management_asg" {
  name                = "management_asg"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_application_security_group" "managed_asg" {
  name                = "managed_asg"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

# Network Security Groups

resource "azurerm_network_security_group" "management_nsg" {
  name                = "management_nsg"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_network_security_rule" "management-admin-3001-from-admin" {
  name                                       = "management-admin-3001-from-admin"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "3001"
  source_address_prefix                      = var.admin_location
  destination_application_security_group_ids = [azurerm_application_security_group.management_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "management_nsg"
}

resource "azurerm_network_security_rule" "management-ssh-22" {
  name                                       = "management-ssh-22"
  priority                                   = 101
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = var.admin_location
  destination_application_security_group_ids = [azurerm_application_security_group.management_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "management_nsg"
}

resource "azurerm_network_security_rule" "management-admin-3001" {
  name                                       = "management-admin-3001"
  priority                                   = 102
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "3001"
  source_application_security_group_ids      = [azurerm_application_security_group.managed_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.management_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "management_nsg"
}

resource "azurerm_network_security_group" "managed_nsg" {
  name                = "managed_nsg"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_network_security_rule" "managed-cpn-2222" {
  name                                       = "managed-cpn-2222"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "2222"
  source_application_security_group_ids      = [azurerm_application_security_group.management_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.managed_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "managed_nsg"
}

resource "azurerm_network_security_rule" "managed-admin-3001" {
  name                                       = "managed-admin-3001"
  priority                                   = 111
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "3001"
  source_application_security_group_ids      = [azurerm_application_security_group.management_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.managed_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "managed_nsg"
}

resource "azurerm_network_security_rule" "managed-logsinkd-48400" {
  name                                       = "managed-logsinkd-48400"
  priority                                   = 112
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "48400"
  source_application_security_group_ids      = [azurerm_application_security_group.management_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.managed_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "managed_nsg"
}

resource "azurerm_network_security_rule" "managed-ssh-22" {
  name                                       = "managed-ssh-"
  priority                                   = 113
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = var.admin_location
  destination_application_security_group_ids = [azurerm_application_security_group.managed_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "managed_nsg"
}

resource "azurerm_network_security_rule" "public-application-ports" {
  count = length(var.lb_mapping)

  name                                       = "public-application-${var.lb_mapping[count.index].dest}"
  priority                                   = 120 + count.index
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = var.lb_mapping[count.index].dest
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.managed_asg.id]
  resource_group_name                        = var.resource_group.name
  network_security_group_name                = "managed_nsg"
}
