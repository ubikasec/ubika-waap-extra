# locals

locals {
  autoreg_admin_apikey = "${base64encode(var.autoreg_admin_user)}@${var.autoreg_admin_apiuid}"
}

### AWS resources

module "ami" {
  source = "../_/ami"

  management_mode = var.management_mode
  managed_mode    = var.managed_mode

  product_version = var.product_version
}

module "management" {
  source = "../_/management"

  context        = local.context
  additional_sgs = concat([aws_security_group.accept_all_out.id], var.additional_management_sgs)
}

module "managed" {
  source = "../_/managed"

  context               = local.context
  additional_sgs        = concat([aws_security_group.accept_all_out.id], var.additional_managed_sgs)
  management_private_ip = module.management.private_ip
}

### Security groups

resource "aws_security_group" "accept_all_out" {
  name   = "accept_all_out"
  vpc_id = var.vpc_id
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs

output "managed_ids" {
  value = module.managed.ids
}

output "management_public_ip" {
  value = module.management.public_ip
}
