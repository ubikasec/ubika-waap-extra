variable "vpc_id" {}
variable "subnet_ids" {}
variable "mapping" {}
variable "healthcheck_path" { default = "" }
variable "lb_name" { default = "rswaf" }
variable "enable_deletion_protection" { default = true }

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
  name        = "lb_monitoring"
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
}

resource "aws_security_group" "web_input" {
  name        = "lb_web_input"
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
