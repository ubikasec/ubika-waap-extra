variable "context" {
  description = ""
}

variable "management_private_ip" {
}

variable "additional_sgs" {
}

resource "aws_security_group" "managed_admin" {
  name        = "managed_admin"
  description = "Enable RS WAF Administration access from the Management instance"
  vpc_id      = var.context.vpc_id
  ingress {
    from_port   = "2222"
    to_port     = "2222"
    protocol    = "tcp"
    cidr_blocks = ["${var.management_private_ip}/32"]
  }
  ingress {
    from_port   = "3001"
    to_port     = "3001"
    protocol    = "tcp"
    cidr_blocks = ["${var.management_private_ip}/32"]
  }
  ingress {
    from_port   = "48400"
    to_port     = "48400"
    protocol    = "tcp"
    cidr_blocks = ["${var.management_private_ip}/32"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.context.admin_location]
  }

  tags = {
    Name               = "${var.context.name_prefix} managed_admin"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

# Managed instances

resource "aws_instance" "managed" {
  count         = var.context.nb_managed
  ami           = var.context.amis.managed
  instance_type = var.context.managed_instance_type
  key_name      = var.context.key_name
  subnet_id     = element(var.context.subnet_ids, count.index)
  monitoring    = true
  vpc_security_group_ids = concat([
    aws_security_group.managed_admin.id,
    ], var.additional_sgs
  )
  # ebs_optimized = true
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = var.context.disk_size.managed
  }
  user_data = jsonencode({
    instance_role = "managed"
    instance_name = "managed_${count.index}"
    linkto_ip     = "${var.management_private_ip}"
    linkto_port   = "3001"
    linkto_apikey = "${var.context.autoreg_admin_apikey}"
  })

  tags = {
    Name               = "${var.context.name_prefix} managed ${count.index}"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

# attach managed instances to target groups
locals {
  need_attachement = setproduct(var.context.target_group_arns, aws_instance.managed.*.id)
}

resource "aws_lb_target_group_attachment" "managed" {
  count = length(var.context.target_group_arns) * length(aws_instance.managed.*.id)

  target_group_arn = element(local.need_attachement, count.index)[0]
  target_id        = element(local.need_attachement, count.index)[1]
}
output "ids" {
  value = aws_instance.managed.*.id
}

output "security_groups" {
  value = concat([
    aws_security_group.managed_admin.id,
    ], var.additional_sgs
  )
}
