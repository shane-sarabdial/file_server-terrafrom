variable "key_pair" {
  description = "keypair for ec2 ssh"
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
  profile = "test_profile"
}

resource "aws_instance" "file_server" {
  ami = "ami-044b654780812c565"
  instance_type = "t2.medium"
  key_name = var.key_pair
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

resource "aws_iam_access_key" "test" {
  user = aws_iam_user.filecloud_user.name
}

output "secret" {
  value = {
    "key"      = aws_iam_access_key.test.id
    "secret"   = aws_iam_access_key.test.secret
  }
  sensitive = true
}