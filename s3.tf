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
    target_bucket = var.s3_logs_bucket_id
    target_prefix = "${var.stage}/efs_logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}


data "aws_iam_policy_document" "logs" {
  statement {
    sid    = "ForceSSLOnlyAccess"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
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
    target_bucket = var.s3_logs_bucket_id
    target_prefix = "${var.stage}/efs_backups/"
  }

  lifecycle_rule {
    enabled = true
    prefix  = "efs"

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "backups" {
  statement {
    sid    = "ForceSSLOnlyAccess"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
    resources = [
      aws_s3_bucket.backups.arn,
      "${aws_s3_bucket.backups.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backups.id
  policy = data.aws_iam_policy_document.backups.json
}

