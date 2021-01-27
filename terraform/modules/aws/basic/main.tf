### Locals

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

    aws_cloudwatch_monitoring = var.aws_cloudwatch_monitoring

    management_instance_type = var.management_instance_type
    managed_instance_type    = var.managed_instance_type

    nb_managed = var.nb_managed

    disk_size = {
      management = var.management_disk_size
      managed    = var.managed_disk_size
    }
  }
}
