module "logs_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.15.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = flatten([compact(concat(var.attributes, ["logs"]))])
  tags       = var.tags
}

resource "aws_s3_bucket" "logs" {
  bucket        = module.logs_label.id
  force_destroy = true
  tags          = module.logs_label.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "${var.s3_logs_bucket_id}"
    target_prefix = "${var.stage}/log/efs_logs/"
  }
}

module "backups_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.15.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = flatten([compact(concat(var.attributes, ["backups"]))])
  tags       = var.tags
}

resource "aws_s3_bucket" "backups" {
  bucket = module.backups_label.id
  tags   = module.backups_label.tags

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "${var.s3_logs_bucket_id}"
    target_prefix = "${var.stage}/log/efs_backups/"
  }

  lifecycle_rule {
    enabled = true
    prefix  = "efs"

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }
  }
}

