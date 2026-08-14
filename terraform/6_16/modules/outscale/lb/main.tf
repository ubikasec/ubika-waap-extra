terraform {
  required_providers {
    outscale = {
      source = "outscale/outscale"
      version = "0.12.0"
    }
  }
}

variable "net_id" {}
variable "subnet_ids" {}
variable "mapping" {}
variable "managed_ids" {}
variable "healthcheck_path" { default = "" }
variable "lb_name" { default = "ubikawaap" }
variable "enable_deletion_protection" { default = true }

resource "random_id" "healthcheck" {
  prefix      = "${var.lb_name}-health-"
  byte_length = 16
}

# load balancer

data "outscale_net" "net" {
  filter {
    name   = "net_ids"
    values = [var.net_id]
  }
}

resource "outscale_load_balancer" "lb" {
  load_balancer_name = "${var.lb_name}"
  load_balancer_type = "internet-facing"
  subnets            = var.subnet_ids

  dynamic "listeners" {
    for_each = var.mapping
    content {
      backend_port           = listeners.value.dest
      backend_protocol       = "TCP"
      load_balancer_protocol = "TCP"
      load_balancer_port     = listeners.value.src
    }
  }
  tags {
    key   = "name"
    value = "outscale_load_balancer01"
  }
}


resource "outscale_security_group" "monitoring" {
  security_group_name = "lb_monitoring"
  description         = "Enable web acces from lb monitoring"
  net_id              = var.net_id
  remove_default_outbound_rule = true
}

resource "outscale_security_group_rule" "monitoring_rule" {
  for_each   = {
    for index, rule in var.mapping:
      rule.name =>  rule
  }
  security_group_id = outscale_security_group.monitoring.id
  flow              = "Inbound"
  from_port_range   = each.value.dest
  to_port_range     = each.value.dest
  ip_protocol       = "tcp"
  ip_range          = data.outscale_net.net.ip_range

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_security_group" "web_input" {
  security_group_name = "lb_web_input"
  description         = "Enable web acces from everywhere"
  net_id              = var.net_id
  remove_default_outbound_rule = true
}

resource "outscale_security_group_rule" "web_input_rule" {
  for_each   = {
    for index, rule in var.mapping:
      rule.name =>  rule
  }
  security_group_id = outscale_security_group.web_input.id
  flow              = "Inbound"
  from_port_range   = each.value.dest
  to_port_range     = each.value.dest
  ip_protocol       = "tcp"
  ip_range          = "0.0.0.0/0"

  lifecycle {
    create_before_destroy = true
  }
}

resource "outscale_load_balancer_vms" "outscale_load_balancer_managed" {
    load_balancer_name = "${var.lb_name}"
    backend_vm_ids     = var.managed_ids
}

output "security_groups" {
  value = concat(outscale_security_group.monitoring.*.id, outscale_security_group.web_input.*.id)
}

output "public_url" {
  value       = "http://${outscale_load_balancer.lb.dns_name}/"
  description = "Public acces to your application"
}

#output "healthcheck" {
#  value       = var.healthcheck_path != "" ? var.healthcheck_path : "/${random_id.healthcheck.hex}"
#  description = "Loadbalancers healthchecks path"
#}
