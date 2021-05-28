variable "product_version" {}

variable "management_mode" {}
variable "managed_mode" {}
variable "autoscaled_mode" { default = "" }

locals {
  ami_version = replace(var.product_version, ".", "-")
}

data "aws_ami" "byol" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["*${local.ami_version}*2ec64903-39cf-44c2-b4f1-04388ab164ac*"]
  }
}

data "aws_ami" "payg" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["*${local.ami_version}*8d98a8b1-aba2-459f-aa08-109cd5a67a47*"]
  }
}


output "management" {
  value = var.management_mode == "payg" ? data.aws_ami.payg.id : data.aws_ami.byol.id
}
output "managed" {
  value = var.managed_mode == "payg" ? data.aws_ami.payg.id : data.aws_ami.byol.id
}
output "autoscaled" {
  value = var.autoscaled_mode == "byol" ? data.aws_ami.byol.id : data.aws_ami.payg.id
}
