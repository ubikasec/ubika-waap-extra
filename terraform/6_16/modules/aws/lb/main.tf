variable "vpc_id" {}
variable "subnet_ids" {}
variable "mapping" {}
variable "healthcheck_path" { default = "" }
variable "lb_name" {
  # ELBv2 names are capped at 32 chars and Terraform appends a 26-char unique id
  # to name_prefix, leaving 6 chars for "${lb_name}-" -- hence 5 for lb_name.
  # The AWS provider does not check this statically, so without the validation
  # below an over-long value only fails at apply time.
  default = "waap"

  validation {
    condition     = length(var.lb_name) <= 5 && length(regexall("^[0-9A-Za-z]+$", var.lb_name)) == 1
    error_message = "lb_name must be 1-5 alphanumeric chars: ELBv2 caps names at 32 and Terraform appends a 26-char suffix to \"${"$"}{lb_name}-\"."
  }
}
variable "enable_deletion_protection" { default = false }

resource "random_id" "healthcheck" {
  prefix      = "${var.lb_name}-health-"
  byte_length = 16
}

# load balancer

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_lb" "lb" {
  name_prefix        = "${var.lb_name}-"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
}

resource "aws_lb_listener" "lb_listener" {
  count             = length(var.mapping)
  load_balancer_arn = aws_lb.lb.arn
  port              = var.mapping[count.index].src
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb[count.index].arn
  }
}

resource "aws_lb_target_group" "lb" {
  count       = length(var.mapping)
  name_prefix = "${var.lb_name}-"
  port        = var.mapping[count.index].dest
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  health_check {
    interval            = "10"
    protocol            = var.mapping[count.index].proto
    port                = var.mapping[count.index].dest
    path                = var.healthcheck_path != "" ? var.healthcheck_path : "/${random_id.healthcheck.hex}"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
  }
  tags = {
    Name = "${var.lb_name} ${var.mapping[count.index].name}"
  }
}


resource "aws_security_group" "monitoring" {
  name_prefix = "lb_monitoring"
  description = "Enable web acces from lb monitoring"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = var.mapping
    content {
      from_port   = ingress.value.dest
      to_port     = ingress.value.dest
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.lb_name} lb_monitoring"
  }
}

resource "aws_security_group" "web_input" {
  name_prefix = "lb_web_input"
  description = "Enable web acces from everywhere"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = var.mapping
    content {
      from_port   = ingress.value.dest
      to_port     = ingress.value.dest
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.lb_name} lb_web_input"
  }
}

output "target_group_arns" {
  value = aws_lb_target_group.lb.*.arn
}

output "security_groups" {
  value = concat(aws_security_group.monitoring.*.id, aws_security_group.web_input.*.id)
}

output "public_url" {
  value       = "http://${aws_lb.lb.dns_name}/"
  description = "Public acces to your application"
}

output "healthcheck" {
  value       = var.healthcheck_path != "" ? var.healthcheck_path : "/${random_id.healthcheck.hex}"
  description = "Loadbalancers healthchecks path"
}
