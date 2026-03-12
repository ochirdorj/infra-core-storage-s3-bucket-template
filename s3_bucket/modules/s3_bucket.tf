##############################################################################
# DATA SOURCES
##############################################################################

data "aws_caller_identity" "current" {}


##############################################################################
# S3 BUCKETS
##############################################################################

resource "aws_s3_bucket" "example" {
  bucket              = var.bucket_name
  object_lock_enabled = var.lock_object

  tags = {
    Environment = var.tag_Environment
    Managed_By  = var.tag_Managed_By
    Project     = var.tag_Project
    Team        = var.tag_Team
    Owner       = var.tag_Owner
  }
}

resource "aws_s3_bucket" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${var.bucket_name}-logging"

  tags = {
    Environment = var.tag_Environment
    Managed_By  = var.tag_Managed_By
    Project     = var.tag_Project
    Team        = var.tag_Team
    Owner       = var.tag_Owner
  }
}


##############################################################################
# OWNERSHIP CONTROLS
##############################################################################

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_ownership_controls" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    object_ownership = var.logging_object_ownership
  }
}


##############################################################################
# PUBLIC ACCESS BLOCK
##############################################################################

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = var.block_acls
  block_public_policy     = var.block_policy
  ignore_public_acls      = var.ignore_acls
  restrict_public_buckets = var.restrict_buckets
}

resource "aws_s3_bucket_public_access_block" "logging" {
  count                   = var.enable_logging ? 1 : 0
  bucket                  = aws_s3_bucket.logging[0].id
  block_public_acls       = var.block_acls
  block_public_policy     = var.block_policy
  ignore_public_acls      = var.ignore_acls
  restrict_public_buckets = var.restrict_buckets
}


##############################################################################
# BUCKET POLICY
##############################################################################

data "aws_iam_policy_document" "logging_bucket_policy" {
  count = var.enable_logging ? 1 : 0

  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logging[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].bucket
  policy = data.aws_iam_policy_document.logging_bucket_policy[0].json
}


##############################################################################
# VERSIONING
##############################################################################

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = var.bucket_versioning_status
  }
}

resource "aws_s3_bucket_versioning" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  versioning_configuration {
    status = var.bucket_versioning_status
  }
}


##############################################################################
# ENCRYPTION
##############################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm

      # AES256 + null/empty  = S3 managed encryption
      # aws:kms + null/empty = AWS managed KMS key
      # aws:kms + arn        = Customer managed KMS key
      kms_master_key_id = var.sse_algorithm == "aws:kms" && var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  count  = var.enable_logging && var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" && var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}


##############################################################################
# LIFECYCLE CONFIGURATION
##############################################################################

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  count  = var.enable_life_cycle_rules ? 1 : 0
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "log-expiration-rule"
    status = "Enabled"

    filter {
      and {
        prefix = var.object_prefix
        tags = {
          rule = var.object_tag
        }
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = var.current_transition_days
      storage_class = var.current_transition_storage_class
    }

    expiration {
      days = var.current_expiration_days
    }

    noncurrent_version_transition {
      noncurrent_days = var.non_current_transition_days
      storage_class   = var.non_current_transition_storage_class
    }

    noncurrent_version_expiration {
      noncurrent_days = var.non_current_expiration_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    id     = "logging-expiration-rule"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = var.current_transition_days
      storage_class = var.current_transition_storage_class
    }

    expiration {
      days = var.current_expiration_days
    }

    noncurrent_version_transition {
      noncurrent_days = var.non_current_transition_days
      storage_class   = var.non_current_transition_storage_class
    }

    noncurrent_version_expiration {
      noncurrent_days = var.non_current_expiration_days
    }
  }
}


##############################################################################
# OBJECT LOCK
##############################################################################

resource "aws_s3_bucket_object_lock_configuration" "example" {
  count = var.lock_object ? 1 : 0

  depends_on = [aws_s3_bucket_versioning.example]

  bucket              = aws_s3_bucket.example.id
  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode  = var.object_lock_mode
      years = var.years
    }
  }
}


##############################################################################
# LOGGING
##############################################################################

resource "aws_s3_bucket_logging" "example" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.example.bucket
  target_bucket = aws_s3_bucket.logging[0].bucket
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}


##############################################################################
# REPLICATION
##############################################################################

resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.bucket_name}-replication-policy"
  role  = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.example.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = "${aws_s3_bucket.example.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = "${var.replication_destination_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "example" {
  count  = var.enable_replication ? 1 : 0
  bucket = aws_s3_bucket.example.id
  role   = aws_iam_role.replication[0].arn

  depends_on = [aws_s3_bucket_versioning.example]

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = var.replication_destination_bucket_arn
      storage_class = "STANDARD"
    }
  }
}


##############################################################################
# TRANSFER ACCELERATION
##############################################################################

resource "aws_s3_bucket_accelerate_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  status = var.transfer_acceleration
}


##############################################################################
# WEBSITE CONFIGURATION
##############################################################################

resource "aws_s3_bucket_website_configuration" "example" {
  count  = var.website_enable ? 1 : 0
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = var.key_prefix_equals
    }
    redirect {
      replace_key_prefix_with = var.replace_key_prefix_with
    }
  }
}
