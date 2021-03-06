provider "aws" {}

data "aws_caller_identity" "_" {}
data "aws_region" "_" {}


locals {
  name_suffix = format("terraform-remote-state-%s-%s", data.aws_region._.name, data.aws_caller_identity._.id)
  name_suffix_final = var.environment == "" ? local.name_suffix : format("%s-%s", local.name_suffix, var.environment)
}


resource "aws_kms_key" "encrypt_key" {
}

resource "aws_s3_bucket" "bucket" {
  depends_on = [
    aws_kms_key.encrypt_key]
  bucket = format("s3-%s", local.name_suffix_final)
  tags = var.tags

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.encrypt_key.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_dynamodb_table" "lock_table" {
  name = format("dynamodb-%s", local.name_suffix_final)
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = var.tags
}
