# locals

locals {
  autoreg_admin_apikey = "${base64encode(var.autoreg_admin_user)}@${var.autoreg_admin_apiuid}"
}

### Outscale resources

module "image" {
  source = "../_/image"

  management_mode = var.management_mode
  managed_mode    = var.managed_mode

  product_version = var.product_version
}

module "management" {
  source = "../_/management"

  context        = local.context
  additional_sgs = concat([outscale_security_group.accept_all_out.id], var.additional_management_sgs)
}

module "managed" {
  source = "../_/managed"

  context               = local.context
  additional_sgs        = concat([outscale_security_group.accept_all_out.id], var.additional_managed_sgs)
  management_private_ip = module.management.private_ip
}

### Security groups

resource "outscale_security_group" "accept_all_out" {
  security_group_name          = "accept_all_out"
  net_id                       = var.net_id
  remove_default_outbound_rule = true
}

resource "outscale_security_group_rule" "accept_all_out" {
  security_group_id = outscale_security_group.accept_all_out.id
  flow              = "Outbound"
  from_port_range   = "0"
  to_port_range     = "0"
  ip_protocol       = "-1"
  ip_range          = "0.0.0.0/0"
}

# Outputs

output "managed_ids" {
  value = module.managed.ids
}

output "management_public_ip" {
  value = module.management.public_ip
}
