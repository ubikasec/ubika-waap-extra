variable "context" {}
variable "additional_sgs" {}


# Management instance
resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  location            = var.context.resource_group.location
  resource_group_name = var.context.resource_group.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "primary" {
  name                = "management-nic"
  location            = var.context.resource_group.location
  resource_group_name = var.context.resource_group.name

  ip_configuration {
    name                          = "management_ip"
    subnet_id                     = var.context.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_associations" {
  network_interface_id      = azurerm_network_interface.primary.id
  network_security_group_id = var.context.management_nsg
}

resource "azurerm_network_interface_application_security_group_association" "asg_associations" {
  network_interface_id          = azurerm_network_interface.primary.id
  application_security_group_id = var.context.management_asg
}

resource "azurerm_virtual_machine" "management" {
  name                  = "management-vm"
  location              = var.context.resource_group.location
  resource_group_name   = var.context.resource_group.name
  network_interface_ids = [azurerm_network_interface.primary.id]
  vm_size               = var.context.management_instance_type

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.context.images.publisher
    offer     = var.context.images.offer
    sku       = var.context.images.management
    version   = var.context.images.version
    # id = var.context.images.id_management
  }
  plan {
    name      = var.context.images.management
    publisher = var.context.images.publisher
    product   = var.context.images.offer
  }
  storage_os_disk {
    name              = "management_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.context.disk_size.management
  }
  os_profile {
    computer_name  = "management"
    admin_username = var.context.system_admin_user
    custom_data = jsonencode({
      instance_role        = "management"
      instance_name        = "management"
      admin_user           = var.context.admin_user
      admin_password       = var.context.admin_pwd
      admin_apiuid         = var.context.admin_apiuid
      admin_multiuser      = true
      enable_autoreg_admin = true
      autoreg_admin_apiuid = var.context.autoreg_admin_apiuid
    })
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.context.system_admin_user}/.ssh/authorized_keys"
      key_data = var.context.ssh_key_data
    }
  }
  tags = {
    Name               = "${var.context.name_prefix} management"
    RSWAF_Cluster_Name = var.context.cluster_name
  }

  depends_on = [
    azurerm_network_interface_application_security_group_association.asg_associations,
    azurerm_network_interface_security_group_association.nsg_associations
  ]
}

output "private_ip" {
  value = azurerm_network_interface.primary.private_ip_address
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

