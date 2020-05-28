variable "context" {}
variable "management_private_ip" {}
variable "additional_sgs" {}


# Managed instances
resource "azurerm_public_ip" "public_ip" {
  count = var.context.nb_managed

  name                = "managed_public_ip_${count.index}"
  location            = var.context.resource_group.location
  resource_group_name = var.context.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "primary" {
  count = var.context.nb_managed

  name                      = "managed-nic_${count.index}"
  location                  = var.context.resource_group.location
  resource_group_name       = var.context.resource_group.name
  network_security_group_id = var.context.managed_nsg

  ip_configuration {
    name                          = "managed_ip_${count.index}"
    subnet_id                     = var.context.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

resource "azurerm_network_interface_application_security_group_association" "asg_associations" {
  count                         = var.context.nb_managed
  network_interface_id          = azurerm_network_interface.primary[count.index].id
  ip_configuration_name         = "managed_ip_${count.index}"
  application_security_group_id = var.context.managed_asg
}

resource "azurerm_virtual_machine" "managed" {
  count                 = var.context.nb_managed
  name                  = "managed-vm_${count.index}"
  location              = var.context.resource_group.location
  resource_group_name   = var.context.resource_group.name
  network_interface_ids = [azurerm_network_interface.primary[count.index].id]
  vm_size               = var.context.managed_instance_type

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.context.images.publisher
    offer     = var.context.images.offer
    sku       = var.context.images.managed
    version   = var.context.images.version
    # id = var.context.images.id_managed
  }
  plan {
    name      = var.context.images.managed
    publisher = var.context.images.publisher
    product   = var.context.images.offer
  }
  storage_os_disk {
    name              = "managed-os-disk_${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.context.disk_size.managed
  }
  os_profile {
    computer_name  = "managed${count.index}"
    admin_username = var.context.system_admin_user
    custom_data = jsonencode({
      instance_role = "managed"
      instance_name = "managed_${count.index}"
      linkto_ip     = "${var.management_private_ip}"
      linkto_port   = "3001"
      linkto_apikey = "${var.context.autoreg_admin_apikey}"
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
    Name               = "${var.context.name_prefix} managed ${count.index}"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

# attach managed instances to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "pool_association" {
  count = var.context.nb_managed

  ip_configuration_name   = "managed_ip_${count.index}"
  network_interface_id    = azurerm_network_interface.primary[count.index].id
  backend_address_pool_id = var.context.backend_pool_id
}

output "ids" {
  value = azurerm_virtual_machine.managed.*.id
}
