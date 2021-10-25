variable "context" {}
variable "additional_sgs" {}

data "aws_vpc" "vpc" {
  id = var.context.vpc_id
}

resource "aws_security_group" "management_adm" {
  name        = "management_admin"
  description = "Enable RS WAF Administration access"
  vpc_id      = var.context.vpc_id
  ingress {
    from_port   = "3001"
    to_port     = "3001"
    protocol    = "tcp"
    cidr_blocks = [var.context.admin_location]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.context.admin_location]
  }

  tags = {
    Name               = "${var.context.name_prefix} management_admin"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

resource "aws_security_group" "management_from_managed" {
  name        = "management_from_managed"
  description = "Enable RS WAF Administration access from managed instances for auto-registration"
  vpc_id      = var.context.vpc_id
  ingress {
    from_port   = "3001"
    to_port     = "3001"
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name               = "${var.context.name_prefix} management_from_managed"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

# Management instance

resource "aws_instance" "management" {
  ami           = var.context.amis.management
  instance_type = var.context.management_instance_type
  key_name      = var.context.key_name
  subnet_id     = var.context.subnet_ids[0]
  vpc_security_group_ids = concat([
    aws_security_group.management_adm.id,
    aws_security_group.management_from_managed.id, ],
    var.additional_sgs
  )
  associate_public_ip_address = true
  # ebs_optimized = true
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = var.context.disk_size.management
  }
  user_data = jsonencode({
    instance_role             = "management"
    instance_name             = "management"
    admin_user                = var.context.admin_user
    admin_password            = var.context.admin_pwd
    admin_apiuid              = var.context.admin_apiuid
    admin_multiuser           = true
    enable_autoreg_admin      = true
    autoreg_admin_apiuid      = var.context.autoreg_admin_apiuid
    aws_cloudwatch_monitoring = var.context.aws_cloudwatch_monitoring
  })

  iam_instance_profile = aws_iam_instance_profile.management.name

  tags = {
    Name               = "${var.context.name_prefix} management"
    RSWAF_Cluster_Name = var.context.cluster_name
  }
}

resource "aws_iam_instance_profile" "management" {
  name = "RS-WAF-Cloud-management-profile"
  role = aws_iam_role.management.name
}

resource "aws_iam_role" "management" {
  name = "RS-WAF-Cloud-management-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json
}

data "aws_iam_policy_document" "assume_management" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_management" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "management" {
  name   = "RS-WAF-Cloud-management-policy"
  policy = data.aws_iam_policy_document.cloudwatch_management.json
}

resource "aws_iam_role_policy_attachment" "management" {
  role       = aws_iam_role.management.name
  policy_arn = aws_iam_policy.management.arn
}

output "private_ip" {
  value = aws_instance.management.private_ip
}

output "public_ip" {
  value = aws_instance.management.public_ip
}
