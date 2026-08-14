### Locals

locals {
  # IAM names are account-global, so they must derive from name_prefix to let
  # several clusters coexist. IAM only accepts [A-Za-z0-9+=,.@_-] and caps
  # role/profile names at 64 chars; the longest suffix appended by the
  # submodules is "-management-profile" (19 chars).
  iam_prefix_raw = replace(trimspace(var.name_prefix), "/[^a-zA-Z0-9+=,.@_-]+/", "-")
  iam_prefix     = substr(local.iam_prefix_raw, 0, min(45, length(local.iam_prefix_raw)))
}

locals {
  context = {
    vpc_id            = var.vpc_id
    subnet_ids        = var.subnet_ids
    target_group_arns = var.target_group_arns

    amis = module.ami

    name_prefix  = var.name_prefix
    iam_prefix   = local.iam_prefix
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
