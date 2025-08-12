### Locals

locals {
  context = {
    resource_group  = var.resource_group
    subnet          = var.subnet
    backend_pool_id = var.backend_pool_id

    images = module.image

    name_prefix  = var.name_prefix
    cluster_name = var.cluster_name == "" ? var.name_prefix : var.cluster_name

    admin_location = var.admin_location
    ssh_key_data   = var.ssh_key_data
    admin_user     = var.admin_user
    admin_apiuid   = var.admin_apiuid
    admin_pwd      = var.admin_pwd

    autoreg_admin_user   = var.autoreg_admin_user
    autoreg_admin_apiuid = var.autoreg_admin_apiuid
    autoreg_admin_apikey = local.autoreg_admin_apikey

    lb_mapping = var.lb_mapping

    management_asg = azurerm_application_security_group.management_asg.id
    management_nsg = azurerm_network_security_group.management_nsg.id
    managed_asg    = azurerm_application_security_group.managed_asg.id
    managed_nsg    = azurerm_network_security_group.managed_nsg.id

    system_admin_user = "cloud-user"

    management_instance_type = var.management_instance_type
    managed_instance_type    = var.managed_instance_type

    nb_managed = var.nb_managed

    disk_size = {
      management = var.management_disk_size
      managed    = var.managed_disk_size
    }
  }
}

### Azure resources

module "management" {
  source = "../_/management"

  context        = local.context
  additional_sgs = var.additional_management_sgs
}

module "managed" {
  source = "../_/managed"

  context               = local.context
  additional_sgs        = var.additional_managed_sgs
  management_private_ip = module.management.private_ip
}

output "managed_ids" {
  value = module.managed.ids
}

output "management_public_ip" {
  value = module.management.public_ip
}
