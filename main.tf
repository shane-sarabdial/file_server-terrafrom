variable "key_pair" {
  description = "keypair for ec2 ssh"
}

variable "ami-id" {
  description = "ami id"
}

variable "instance" {
  description = "file cloud instance type"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  shared_config_files      = ["/Users/shane/.aws/conf"]
  shared_credentials_files = ["/Users/shane/.aws/credentials"]
  profile = "default"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "fc_sg" {
  name = "fc-sg"
  description = "Allow HTTP/S and SSH"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_https" {
 type              = "ingress"
 description       = "HTTPS ingress"
 from_port         = 443
 to_port           = 443
 protocol          = "tcp"
 cidr_blocks       = ["0.0.0.0/0"]
 security_group_id = aws_security_group.fc_sg.id
}

resource "aws_security_group_rule" "allow_http" {
 type              = "ingress"
 description       = "HTTP ingress"
 from_port         = 80
 to_port           = 80
 protocol          = "tcp"
 cidr_blocks       = ["0.0.0.0/0"]
 security_group_id = aws_security_group.fc_sg.id
}

resource "aws_security_group_rule" "allow_all" {
 type              = "egress"
 description       = "allow all"
 from_port         = 0
 to_port           = 0
 protocol          = "-1"
 cidr_blocks       = ["0.0.0.0/0"]
 security_group_id = aws_security_group.fc_sg.id
}
resource "aws_security_group_rule" "allow_ssh" {
 type              = "ingress"
 description       = "SSH ingress"
 from_port         = 22
 to_port           = 22
 protocol          = "tcp"
 cidr_blocks       = ["0.0.0.0/0"]
 security_group_id = aws_security_group.fc_sg.id
}

resource "aws_instance" "file_server" {
  ami = var.ami-id
  instance_type = var.instance
  key_name = var.key_pair
  vpc_security_group_ids = [aws_security_group.fc_sg.id]
  tags = {
    Name = "file server"
  }
}

resource "aws_s3_bucket" "storage_s3" {
  bucket = "my-fs-storage"
  tags = {
    Name = "file server storage"
  }
}

resource "aws_iam_user" "filecloud_user" {
  name = "fc_user"
}

data "aws_iam_policy_document" "filecloud_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:CreateBucket",
              "s3:DeleteObject",
              "s3:GetObject",
              "s3:ListBucket",
              "s3:PutObject"]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_user_policy" "filecloud_policy" {
  name = "fcp"
  user = aws_iam_user.filecloud_user.name
  policy = data.aws_iam_policy_document.filecloud_policy.json
}

resource "aws_iam_access_key" "fc_user_access_key" {
  user = aws_iam_user.filecloud_user.name
}

output "secret" {
  value = {
    "key"      = aws_iam_access_key.fc_user_access_key.id
    "secret"   = aws_iam_access_key.fc_user_access_key.secret
  }
  sensitive = true
}