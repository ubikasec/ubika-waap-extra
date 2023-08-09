variable "product_version" {}

variable "management_mode" {}
variable "managed_mode" {}
variable "autoscaled_mode" { default = "" }

locals {
  ami_version = replace(var.product_version, ".", "-")
}

data "aws_ami" "byol" {
  # owners = ["self"]
  # filter {
  #   name   = "image-id"
  #   values = ["ami-0ecefd9acaa8ce3d5"]
  # }
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["*${local.ami_version}*2c582404-e2f1-4bf5-81e9-ff3412896971*"]
  }
}

data "aws_ami" "payg" {
  # owners = ["self"]
  # filter {
  #   name   = "image-id"
  #   values = ["ami-0ecefd9acaa8ce3d5"]
  # }
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["*${local.ami_version}*b53b4621-53d7-4af3-9cb8-b04307945861*"]
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
