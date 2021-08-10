### Locals

locals {
  admin_apikey = "${base64encode(var.admin_user)}@${var.admin_apiuid}"
}

locals {
  context = {
    vpc_id            = var.vpc_id
    subnet_ids        = var.subnet_ids
    target_group_arns = var.target_group_arns

    amis = module.ami

    name_prefix  = var.name_prefix
    cluster_name = var.cluster_name == "" ? var.name_prefix : var.cluster_name

    admin_location = var.admin_location
    key_name       = var.key_name
    admin_user     = var.admin_user
    admin_apiuid   = var.admin_apiuid
    admin_pwd      = var.admin_pwd

    autoreg_admin_user   = var.autoreg_admin_user
    autoreg_admin_apiuid = var.autoreg_admin_apiuid
    autoreg_admin_apikey = local.autoreg_admin_apikey

    management_instance_type = var.management_instance_type
    managed_instance_type    = var.managed_instance_type

    nb_managed = var.nb_managed

    disk_size = {
      management = var.management_disk_size
      managed    = var.managed_disk_size
      autoscaled = var.autoscaled_disk_size
    }

    # autoscaler part
    autoscaler = {
      min_size                  = var.autoscaler_min_size
      max_size                  = var.autoscaler_max_size < var.nb_managed ? var.nb_managed : var.autoscaler_max_size
      default_cooldown          = var.autoscaler_default_cooldown
      health_check_type         = var.autoscaler_health_check_type
      health_check_grace_period = var.autoscaler_health_check_grace_period
      termination_policies      = var.autoscaler_termination_policies
    }
  }
}

### AWS resources

module "autoscaling" {
  source = "../_/autoscaling"

  context = local.context

  security_groups       = module.managed.security_groups
  management_private_ip = module.management.private_ip

  autoscaled_clone_source = var.autoscaled_clone_source
}

# Outputs

output "autoscaling_group_name" {
  value = module.autoscaling.autoscaling_group_name
}
