data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "logging" {
  count = var.enable_logging ? 1 : 0
  bucket = "${var.bucket_name}-logging"
}

data "aws_iam_policy_document" "logging_bucket_policy" {
  count = var.enable_logging ? 1 : 0

  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type = "Service"
    }
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logging[0].arn}/*"]
    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  count = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].bucket
  policy = data.aws_iam_policy_document.logging_bucket_policy[0].json
}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  object_lock_enabled = var.lock_object 

  tags = {
    Environment = var.tag_Environment
    Project_Name = var.tag_Project_Name
    Team = var.tag_Team
    Owner = var.tag_Owner
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = var.bucket_versioning_status
  }
}

resource "aws_s3_bucket_object_lock_configuration" "example" {
  count = var.lock_object ? 1 : 0 
  
  depends_on = [aws_s3_bucket_versioning.example] 

  bucket = aws_s3_bucket.example.id
  object_lock_enabled = "Enabled" 

  rule {
    default_retention {
      mode = var.object_lock_mode
      years = var.years
    }
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket_access_block" {
  bucket = aws_s3_bucket.example.id
  block_public_acls = var.block_acls
  block_public_policy = var.block_policy
  ignore_public_acls = var.ignore_acls
  restrict_public_buckets = var.restrict_buckets
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  count = var.enable_life_cycle_rules ? 1 : 0
  bucket = aws_s3_bucket.example.id

  rule {
    id = "log-expiration-rule"
    status = "Enabled"

    filter {
      and {
      prefix = var.object_prefix

      tags = {
        rule = var.object_tag
      }  
      }
    }
  
 transition {
   days = var.current_transition_days
   storage_class = var.current_transition_storage_class
 }

 expiration {
   days = var.current_expiration_days
 }

  noncurrent_version_transition {
    noncurrent_days = var.non_current_transition_days
    storage_class = var.non_current_transition_storage_class
  }

  noncurrent_version_expiration {
    noncurrent_days = var.non_current_expiration_days
  }
 }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm

      # Only include kms_master_key_id if algorithm is aws:kms
      #It will work as a combination. 
      #AES256+null or empty = AES256 S3 managed encryption
      #aws:kms+null or empty =aws managed kms key
      #aws:kms+arn:aws:kms=cumtomer manager kms key
      kms_master_key_id = var.sse_algorithm == "aws:kms" && var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_accelerate_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  status = var.transfer_acceleration
}

resource "aws_s3_bucket_logging" "example" {
  count = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.example.bucket
  target_bucket = aws_s3_bucket.logging[0].bucket
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id
  count = var.website_enable ? 1 : 0

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