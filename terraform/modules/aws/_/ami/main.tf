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
    values = ["*${local.ami_version}*51ccfbfd-99a5-402d-90c3-427dd2bc23c5*"]
  }
}

data "aws_ami" "payg" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["*${local.ami_version}*8f8b8e5f-331f-4d1d-ae38-4a68f04f25be*"]
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
