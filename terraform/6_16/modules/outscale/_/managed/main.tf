terraform {
  required_providers {
    outscale = {
      source = "outscale/outscale"
      version = "0.12.0"
    }
  }
}

variable "context" {}
variable "additional_sgs" {}
variable "management_private_ip" {}

resource "outscale_security_group" "managed_admin" {
  security_group_name = "managed_admin"
  description         = "Enable WAAP Administration access from the Management instance"
  net_id              = var.context.net_id
  remove_default_outbound_rule = true

  tags {
    key   = "Name"
    value = "${var.context.name_prefix} managed_admin"
    
  }
  tags {
    key   = "WAAP_Cluster_Name"
    value = var.context.cluster_name
  }
}

resource "outscale_security_group_rule" "managed_admin_2222" {
  security_group_id = outscale_security_group.managed_admin.id
  flow              = "Inbound"
  from_port_range   = "2222"
  to_port_range     = "2222"
  ip_protocol       = "tcp"
  ip_range          = "${var.management_private_ip}/32"

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_security_group_rule" "managed_admin_3001" {
  security_group_id = outscale_security_group.managed_admin.id
  flow              = "Inbound"
  from_port_range   = "3001"
  to_port_range     = "3001"
  ip_protocol       = "tcp"
  ip_range          = "${var.management_private_ip}/32"

  lifecycle {
    create_before_destroy = true
  }
}
resource "outscale_security_group_rule" "managed_admin_48400" {
  security_group_id = outscale_security_group.managed_admin.id
  flow              = "Inbound"
  from_port_range   = "48400"
  to_port_range     = "48400"
  ip_protocol       = "tcp"
  ip_range          = "${var.management_private_ip}/32"

  lifecycle {
    create_before_destroy = true
  }
}
resource "outscale_security_group_rule" "managed_admin_22" {
  security_group_id = outscale_security_group.managed_admin.id
  flow              = "Inbound"
  from_port_range   = "22"
  to_port_range     = "22"
  ip_protocol       = "tcp"
  ip_range          = var.context.admin_location

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_public_ip" "managed_public_ip" {
  count = var.context.nb_managed
}

# Managed instances

resource "outscale_vm" "managed" {
  count              = var.context.nb_managed
  image_id           = var.context.images.managed
  vm_type            = var.context.managed_instance_type
  keypair_name       = var.context.keypair_name
  subnet_id          = element(var.context.subnet_ids, count.index)
  security_group_ids = concat([
    outscale_security_group.managed_admin.id,
    ], var.additional_sgs
  )
  block_device_mappings {
    device_name = "/dev/sda1"
    bsu {
      volume_type           = "gp2"
      volume_size           = var.context.disk_size.managed
      delete_on_vm_deletion = true
    }
  }
  user_data = base64encode(jsonencode({
    instance_role             = "managed"
    instance_name             = "managed_${count.index}"
    linkto_ip                 = var.management_private_ip
    linkto_port               = "3001"
    linkto_apikey             = var.context.autoreg_admin_apikey
  }))

  tags {
    key   = "Name"
    value = "${var.context.name_prefix} managed ${count.index}"
  }
  tags {
    key   = "WAAP_Cluster_Name"
    value = var.context.cluster_name
  }

}

resource "outscale_public_ip_link" "managed_public_ip_link" {
  count     = var.context.nb_managed
  vm_id     = outscale_vm.managed[count.index].vm_id
  public_ip = outscale_public_ip.managed_public_ip[count.index].public_ip
}

output "ids" {
  value = outscale_vm.managed.*.id
}

output "security_groups" {
  value = concat([
    outscale_security_group.managed_admin.id,
    ], var.additional_sgs
  )
}
