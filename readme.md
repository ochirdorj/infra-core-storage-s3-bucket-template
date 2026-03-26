# AWS S3 Feature-Rich Bucket Module

This Terraform module provisions a highly configurable AWS S3 bucket, including options for:

- Dedicated access logging
- Versioning
- Object lock (WORM)
- Server-side encryption
- Public access block controls
- Robust lifecycle management for current and noncurrent object versions
- Cross-region replication
- Transfer acceleration
- Static website hosting

---

## Features

This module provisions a primary S3 bucket (`aws_s3_bucket.example`) and conditionally provisions a separate logging bucket.

- **Dedicated Logging Bucket**: Optionally creates a second, dedicated bucket (`*-logging`) with a restrictive IAM policy to securely store access logs. The logging bucket also inherits versioning, encryption, and lifecycle settings.
- **Access Controls**: Configures S3 Public Access Block settings (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) on both the primary and logging buckets.
- **Versioning**: Enables versioning on both the primary and logging buckets.
- **Object Lock (WORM)**: Optionally enforces Write Once, Read Many (WORM) compliance with configurable retention mode and duration (`GOVERNANCE` or `COMPLIANCE`).
- **Lifecycle Rules**: Applies granular rules for transitioning and expiring both current and noncurrent object versions based on prefix and tag filters. Also includes an automatic abort rule for incomplete multipart uploads (7 days).
- **Server-Side Encryption**: Optionally enforces AES256 or KMS encryption. Supports AWS-managed KMS keys or customer-managed KMS keys (CMK) via ARN.
- **Cross-Region Replication**: Optionally configures S3 replication to a destination bucket with a dedicated IAM role and policy.
- **Transfer Acceleration**: Optionally enables S3 Transfer Acceleration.
- **Website Hosting**: Optionally enables static website hosting with `index.html`/`error.html` documents and prefix-based routing rules.

---

## Usage Example

```hcl
module "s3_feature_bucket" {
  source = "./modules/s3-bucket" # Update path as needed

  # --- Core Bucket Configuration ---
  bucket_name              = "my-secure-data-storage-2025"
  bucket_versioning_status = "Enabled"
  transfer_acceleration    = "Enabled"

  # --- Tagging ---
  tag_Environment = "production"
  tag_Managed_By  = "Terraform"
  tag_Project     = "ap13"
  tag_Team        = "DevOps"
  tag_Owner       = "team@example.com"

  # --- Logging Configuration ---
  enable_logging = true

  # --- Object Lock (WORM) Configuration ---
  lock_object      = true
  object_lock_mode = "GOVERNANCE"
  years            = "5"

  # --- Public Access Block Configuration ---
  block_acls       = true
  block_policy     = true
  ignore_acls      = true
  restrict_buckets = true

  # --- Lifecycle Management ---
  enable_life_cycle_rules          = true
  object_prefix                    = "logs/"
  object_tag                       = "archive-candidate"
  current_transition_days          = 30
  current_transition_storage_class = "STANDARD_IA"
  current_expiration_days          = 90
  non_current_transition_days      = "60"
  non_current_transition_storage_class = "GLACIER"
  non_current_expiration_days      = 180

  # --- Encryption Configuration ---
  enable_encryption = true
  sse_algorithm     = "aws:kms"
  kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/your-key-id"

  # --- Cross-Region Replication ---
  enable_replication                  = false
  replication_destination_bucket_arn  = ""

  # --- Static Website Hosting ---
  website_enable          = false
  key_prefix_equals       = "docs/"
  replace_key_prefix_with = "documents/"
}
```

---

## Inputs

| Name                                  | Description                                                                                              | Type   | Default | Required    |
|---------------------------------------|----------------------------------------------------------------------------------------------------------|--------|---------|-------------|
| `bucket_name`                         | Name of the primary S3 bucket to create.                                                                 | string | n/a     | yes         |
| `bucket_versioning_status`            | Versioning status for the bucket (`Enabled` or `Suspended`).                                             | string | n/a     | yes         |
| `transfer_acceleration`               | Transfer Acceleration status (`Enabled` or `Suspended`).                                                 | string | n/a     | yes         |
| `tag_Environment`                     | Environment tag value.                                                                                   | string | n/a     | yes         |
| `tag_Managed_By`                      | Name of the tool managing this resource (e.g., `Terraform`).                                             | string | n/a     | yes         |
| `tag_Project`                         | Project name tag value.                                                                                  | string | n/a     | yes         |
| `tag_Team`                            | Team tag value.                                                                                          | string | n/a     | yes         |
| `tag_Owner`                           | Owner tag value.                                                                                         | string | n/a     | yes         |
| `enable_logging`                      | If `true`, creates a dedicated logging bucket and enables access logging.                                | bool   | n/a     | yes         |
| `lock_object`                         | Enable S3 Object Lock (WORM). Requires versioning to be enabled.                                        | bool   | n/a     | yes         |
| `object_lock_mode`                    | Object Lock mode (`GOVERNANCE` or `COMPLIANCE`). Required when `lock_object = true`.                    | string | n/a     | conditional |
| `years`                               | Retention duration in years for Object Lock. Required when `lock_object = true`.                        | string | n/a     | conditional |
| `block_acls`                          | Block new public ACLs on the bucket.                                                                    | bool   | n/a     | yes         |
| `block_policy`                        | Block public bucket policies.                                                                           | bool   | n/a     | yes         |
| `ignore_acls`                         | Ignore public ACLs on the bucket.                                                                       | bool   | n/a     | yes         |
| `restrict_buckets`                    | Restrict public access to the bucket.                                                                   | bool   | n/a     | yes         |
| `enable_life_cycle_rules`             | Enable lifecycle configuration.                                                                         | bool   | n/a     | yes         |
| `object_prefix`                       | Object key prefix filter for lifecycle rules. Required when `enable_life_cycle_rules = true`.           | string | n/a     | conditional |
| `object_tag`                          | Object tag filter for lifecycle rules (must be satisfied along with prefix). Required when lifecycle enabled. | string | n/a | conditional |
| `current_transition_days`             | Days before transitioning current object versions to a new storage class.                               | number | n/a     | conditional |
| `current_transition_storage_class`    | Target storage class for current object transition (e.g., `STANDARD_IA`, `GLACIER`).                   | string | n/a     | conditional |
| `current_expiration_days`             | Days before permanently deleting current object versions.                                               | number | n/a     | conditional |
| `non_current_transition_days`         | Days before transitioning noncurrent object versions to a new storage class.                            | string | n/a     | conditional |
| `non_current_transition_storage_class`| Target storage class for noncurrent version transition (e.g., `GLACIER`, `DEEP_ARCHIVE`).              | string | n/a     | conditional |
| `non_current_expiration_days`         | Days before permanently deleting noncurrent object versions.                                            | number | n/a     | conditional |
| `enable_encryption`                   | Enable server-side encryption on the bucket.                                                            | bool   | n/a     | yes         |
| `sse_algorithm`                       | Encryption algorithm (`AES256` or `aws:kms`).                                                          | string | n/a     | conditional |
| `kms_key_arn`                         | ARN of a customer-managed KMS key. Used when `sse_algorithm = "aws:kms"`. Leave empty for AWS-managed key. | string | n/a | conditional |
| `enable_replication`                  | Enable cross-region replication with a dedicated IAM role and policy.                                   | bool   | n/a     | yes         |
| `replication_destination_bucket_arn`  | ARN of the destination bucket for cross-region replication. Required when `enable_replication = true`.  | string | n/a     | conditional |
| `website_enable`                      | Enable static website hosting.                                                                          | bool   | n/a     | yes         |
| `key_prefix_equals`                   | Object key prefix condition for the website routing rule.                                               | string | n/a     | conditional |
| `replace_key_prefix_with`             | Replacement prefix for the website routing redirect.                                                    | string | n/a     | conditional |

---

## Architecture Diagram

```text
                +----------------------+
                |   AWS Account        |
                |  (Caller Identity)   |
                +----------+-----------+
                           |
                           v
               +-----------+----------+
               |   Logging Bucket     |
               |  (optional)          |
               |  - Versioning        |
               |  - Encryption (SSE)  |
               |  - Lifecycle Rules   |
               |  - Public Access Block
               |  - Bucket Policy     |
               |    (logging.s3.amazonaws.com only)
               +-----------+----------+
                           ^
                           | access logs (log/ prefix, partitioned by EventTime)
                           |
               +-----------+----------+
               |   Main S3 Bucket     |
               |----------------------|
               | - Versioning         |
               | - Object Lock (WORM) |
               | - Ownership Controls |
               | - Lifecycle Rules    |
               |   (abort incomplete  |
               |    multipart: 7 days)|
               | - Encryption (SSE)   |
               | - Public Access Block|
               | - Transfer Accel.    |
               | - Website Hosting    |
               +-----------+----------+
                    |             |
                    |             v
                    |    +--------+--------+
                    |    | Website Endpoint |
                    |    | index.html       |
                    |    | error.html       |
                    |    | Routing rules    |
                    |    +------------------+
                    |
                    v (optional, cross-region replication)
               +----+----------------+
               |  Replication IAM    |
               |  Role + Policy      |
               +----+----------------+
                    |
                    v
               +----+--------------------+
               | Destination S3 Bucket   |
               | (another region/account)|
               +-------------------------+
```
