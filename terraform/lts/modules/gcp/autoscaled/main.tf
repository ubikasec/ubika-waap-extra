### Locals

locals {
  context = {
    vpc          = var.vpc
    zones        = var.zones == [] ? data.google_compute_zones.zones.names : var.zones
    region       = var.region == "" ? data.google_client_config.current.region : var.region
    target_pools = var.target_pools

    images            = module.images
    autoscaled_images = module.autoscaled_images.autoscaled

    name_prefix  = var.name_prefix
    cluster_name = var.cluster_name == "" ? var.name_prefix : var.cluster_name

    admin_location = var.admin_location
    admin_user     = var.admin_user
    admin_apiuid   = var.admin_apiuid
    admin_pwd      = var.admin_pwd

    autoreg_admin_user   = var.autoreg_admin_user
    autoreg_admin_apiuid = var.autoreg_admin_apiuid
    autoreg_admin_apikey = local.autoreg_admin_apikey

    management_instance_type = var.management_instance_type
    managed_instance_type    = var.managed_instance_type
    autoscaled_instance_type = var.autoscaled_instance_type

    nb_managed = var.nb_managed

    disk_size = {
      management = var.management_disk_size
      managed    = var.managed_disk_size
      autoscaled = var.autoscaled_disk_size
    }

    # autoscaler part
    autoscaler = {
      health_check_type         = var.autoscaler_health_check_type
      health_check_grace_period = var.autoscaler_health_check_grace_period
      termination_policies      = var.autoscaler_termination_policies
    }
  }
}

### Resources

module "autoscaled_images" {
  source = "../_/images"

  autoscaled_mode = var.autoscaled_mode
  product_version = var.product_version
}

module "autoscaling" {
  source = "../_/autoscaling"

  context = local.context

  management_private_ip   = module.management.private_ip
  managed_template        = module.managed.template
  autoscaled_clone_source = var.autoscaled_clone_source
}

### Outputs

output "instance_group_manager" {
  value = module.autoscaling.instance_group_manager
}
