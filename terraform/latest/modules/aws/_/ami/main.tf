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
    values = ["ubika-waap-byol-${local.ami_version}-*"]
  }
}

data "aws_ami" "payg" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["ubika-waap-payg-${local.ami_version}-*"]
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
