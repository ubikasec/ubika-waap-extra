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

data "outscale_net" "net" {
  filter {
    name   = "net_ids"
    values = [var.context.net_id]
  }
}

resource "outscale_security_group" "management_adm" {
  security_group_name = "management_admin"
  description         = "Enable WAAP Administration access"
  net_id              = var.context.net_id
  remove_default_outbound_rule = true
  tags {
    key   = "Name"
    value = "${var.context.name_prefix} management_admin"
    
  }
  tags {
    key   = "WAAP_Cluster_Name"
    value = var.context.cluster_name
  }
}

resource "outscale_security_group_rule" "management_adm_3001" {
  security_group_id = outscale_security_group.management_adm.id
  flow              = "Inbound"
  from_port_range   = "3001"
  to_port_range     = "3001"
  ip_protocol       = "tcp"
  ip_range          = var.context.admin_location

  lifecycle {
    create_before_destroy = true
  }
}
resource "outscale_security_group_rule" "management_adm_22" {
  security_group_id = outscale_security_group.management_adm.id
  flow              = "Inbound"
  from_port_range   = "22"
  to_port_range     = "22"
  ip_protocol       = "tcp"
  ip_range          = var.context.admin_location

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_security_group" "management_from_managed" {
  security_group_name = "management_from_managed"
  description         = "Enable WAAP Administration access from managed instances for auto-registration"
  net_id              = var.context.net_id
  remove_default_outbound_rule = true

  tags {
    key   = "Name"
    value = "${var.context.name_prefix} management_from_managed"
    
  }
  tags {
    key   = "WAAP_Cluster_Name"
    value = var.context.cluster_name
  }
}

resource "outscale_security_group_rule" "management_from_managed" {
  security_group_id = outscale_security_group.management_from_managed.id
  flow              = "Inbound"
  from_port_range   = "3001"
  to_port_range     = "3001"
  ip_protocol       = "tcp"
  ip_range          = data.outscale_net.net.ip_range

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_public_ip" "management_public_ip" {
}

# Management instance

resource "outscale_vm" "management" {
  image_id           = var.context.images.management
  vm_type            = var.context.management_instance_type
  keypair_name       = var.context.keypair_name
  subnet_id          = var.context.subnet_ids[0]
  security_group_ids = concat([
    outscale_security_group.management_adm.id,
    outscale_security_group.management_from_managed.id, ],
    var.additional_sgs
  )
  #associate_public_ip_address = true
  block_device_mappings {
    device_name = "/dev/sda1"
    bsu {
      volume_type           = "gp2"
      volume_size           = var.context.disk_size.management
      delete_on_vm_deletion = true
    }
  }
  user_data = base64encode(jsonencode({
    instance_role             = "management"
    instance_name             = "management"
    admin_user                = var.context.admin_user
    admin_password            = var.context.admin_pwd
    admin_apiuid              = var.context.admin_apiuid
    admin_multiuser           = true
    enable_autoreg_admin      = true
    autoreg_admin_apiuid      = var.context.autoreg_admin_apiuid
  }))

  tags {
    key   = "Name"
    value = "${var.context.name_prefix} management"
    
  }
  tags {
    key   = "WAAP_Cluster_Name"
    value = var.context.cluster_name
  }
}

resource "outscale_public_ip_link" "management_public_ip_link" {
  vm_id     = outscale_vm.management.vm_id
  public_ip = outscale_public_ip.management_public_ip.public_ip
}

output "private_ip" {
  value = outscale_vm.management.private_ip
}

output "public_ip" {
  value = outscale_vm.management.public_ip
}
