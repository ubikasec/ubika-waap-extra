variable "context" {}
variable "management_private_ip" {}
variable "autoscaled_clone_source" {}
variable "security_groups" {}

# On demand managed instances

resource "aws_autoscaling_group" "managed" {
  name                 = "${var.context.name_prefix} Autoscaling group"
  vpc_zone_identifier  = var.context.subnet_ids
  launch_configuration = aws_launch_configuration.managed.id

  enabled_metrics = ["GroupTotalInstances"]

  min_size = var.context.autoscaler.min_size
  max_size = var.context.autoscaler.max_size

  default_cooldown = var.context.autoscaler.default_cooldown

  health_check_type         = var.context.autoscaler.health_check_type
  health_check_grace_period = var.context.autoscaler.health_check_grace_period

  termination_policies = var.context.autoscaler.termination_policies
  # suspended_processes  = ["ReplaceUnhealthy"]

  target_group_arns = var.context.target_group_arns

  tags = [
    {
      key                 = "Name"
      value               = "${var.context.name_prefix} Autoscaled"
      propagate_at_launch = true
    },
    {
      key                 = "RSWAF_Cluster_Name"
      value               = var.context.cluster_name
      propagate_at_launch = true
  }]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "managed" {
  name_prefix       = "${var.context.name_prefix}-"
  image_id          = var.context.amis.autoscaled
  instance_type     = var.context.managed_instance_type
  key_name          = var.context.key_name
  enable_monitoring = true
  security_groups   = var.security_groups
  # ebs_optimized = true
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = var.context.disk_size.autoscaled
  }
  user_data = jsonencode({
    instance_role = "managed"
    instance_name = "autoscaled_managed_"
    autoscale     = "true"
    cloneof_name  = "${var.autoscaled_clone_source}"
    linkto_ip     = "${var.management_private_ip}"
    linkto_port   = "3001"
    linkto_apikey = "${var.context.autoreg_admin_apikey}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.managed.name
}
