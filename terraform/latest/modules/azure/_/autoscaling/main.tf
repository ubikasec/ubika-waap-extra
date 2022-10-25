variable "context" {}
variable "management_private_ip" {}
variable "autoscaled_clone_source" {}
variable "additional_sgs" {}

# On demand managed instances

resource "azurerm_virtual_machine_scale_set" "managed" {
  name                = "scaleset"
  location            = var.context.resource_group.location
  resource_group_name = var.context.resource_group.name

  upgrade_policy_mode = "Automatic"

  sku {
    name     = var.context.managed_instance_type
    tier     = "Standard"
    capacity = 0
  }

  storage_profile_image_reference {
    publisher = var.context.images.publisher
    offer     = var.context.images.offer
    sku       = var.context.images.autoscaled
    version   = var.context.images.version
    # id = var.context.images.id_autoscaled
  }
  plan {
    name      = var.context.images.autoscaled
    publisher = var.context.images.publisher
    product   = var.context.images.offer
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_profile_data_disk {
    lun           = 0
    create_option = "Empty"
    caching       = "ReadWrite"
    disk_size_gb  = var.context.disk_size.autoscaled

  }
  os_profile {
    computer_name_prefix = "autoscaled-"
    admin_username       = var.context.system_admin_user
    custom_data = jsonencode({
      instance_role   = "managed"
      instance_name   = "autoscaled_managed_"
      autoscale       = "true"
      cloneof_name    = var.autoscaled_clone_source
      linkto_ip       = var.management_private_ip
      linkto_port     = "3001"
      linkto_apikey   = var.context.autoreg_admin_apikey
      datadisk_device = "/dev/disk/azure/scsi1/lun0"
    })
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.context.system_admin_user}/.ssh/authorized_keys"
      key_data = var.context.ssh_key_data
    }
  }

  network_profile {
    name                      = "autoscalednetworkprofile"
    primary                   = true
    network_security_group_id = var.context.managed_nsg

    ip_configuration {
      name                                   = "autoscaled_ip_configuration"
      primary                                = true
      subnet_id                              = var.context.subnet.id
      application_security_group_ids         = [var.context.managed_asg]
      load_balancer_backend_address_pool_ids = [var.context.backend_pool_id]
    }
  }

  tags = {
    Name               = "${var.context.name_prefix} autoscaled managed"
    WAAP_Cluster_Name = var.context.cluster_name
  }
}

output "scale_set_id" {
  value = azurerm_virtual_machine_scale_set.managed.id
}
