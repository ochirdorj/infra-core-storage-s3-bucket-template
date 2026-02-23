# 📁 AWS S3 Feature-Rich Bucket Module

This Terraform module provisions a highly configurable AWS S3 bucket, including options for:

- Dedicated access logging
- Versioning
- Object lock (WORM)
- Server-side encryption
- Public access block controls
- Robust lifecycle management for current and noncurrent object versions
- Bucket Owner Policy
- Transfer acceleration
- Static Web Hosting
---

## ✨ Features

This module provisions a primary S3 bucket (`aws_s3_bucket.example`) and conditionally provisions a separate logging bucket.

- **Dedicated Logging Bucket**: Optionally creates a second, dedicated bucket (`*-logging`) with a restrictive IAM policy to securely store access logs.  
- **Access Controls**: Configures S3 Public Access Block settings (`block_public_acls`, `restrict_public_buckets`, etc.).  
- **Versioning**: Enables versioning control (`aws_s3_bucket_versioning`).  
- **Object Lock (WORM)**: Optionally enforces Write Once, Read Many (WORM) compliance with retention rules (`aws_s3_bucket_object_lock_configuration`).  
- **Lifecycle Rules**: Applies granular rules for transitioning and expiring both Current and Noncurrent (old) object versions based on prefixes and tags.  
- **Server-Side Encryption**: Optionally enforces AES256 or KMS encryption with dynamic KMS key ARN selection.  
- **Transfer Acceleration**: Optionally enables S3 Transfer Acceleration.  
- **Website Hosting**: Optionally enables static website hosting with index/error documents and basic routing rules.  

---

## 🛠️ Usage Example

```hcl
module "s3_feature_bucket" {
  source  = "./modules/s3-bucket" # Update path as needed

  # --- Core Bucket Configuration ---
  bucket_name                = "my-secure-data-storage-2025"
  bucket_versioning_status   = "Enabled"
  transfer_acceleration      = "Enabled"
  
  # --- Logging Configuration (Enabled) ---
  enable_logging             = true

  # --- Tagging ---
  tag_Environment            = "Infra"
  tag_Project_Name           = "ap13"
  tag_Team                   = "DevOps"
  tag_Owner                  = "eenkhchuluun@akumoproject.com"
  
  # --- Object Lock (WORM) Configuration (Enabled) ---
  lock_object                = true
  object_lock_mode           = "GOVERNANCE"
  years                      = 5

  # --- Public Access Block Configuration ---
  block_acls                 = true
  block_policy               = true
  ignore_acls                = true
  restrict_buckets           = true

  # --- Lifecycle Management (Enabled) ---
  enable_life_cycle_rules    = true
  object_prefix              = "logs/"
  object_tag                 = "archive-candidate"
  
  # Current Version Rules
  current_transition_days          = 30
  current_transition_storage_class = "STANDARD_IA"
  current_expiration_days          = 90 

  # Noncurrent Version Rules
  non_current_transition_days        = 60
  non_current_transition_storage_class = "GLACIER"
  non_current_expiration_days        = 180

  # --- Encryption Configuration (Enabled) ---
  enable_encryption          = true
  sse_algorithm              = "aws:kms"
  kms_key_arn                = "arn:aws:kms:us-east-1:123456789012:key/..."
  
  # --- Static Website (Disabled) ---
  website_enable             = true
}

## 📥 Inputs

| Name                               | Description                                                                 | Type   | Default | Required     |
|------------------------------------|-----------------------------------------------------------------------------|--------|---------|--------------|
| bucket_name                        | The name of the primary S3 bucket to create.                                | string | n/a     | yes          |
| bucket_versioning_status           | Versioning status for the bucket (`Enabled` or `Suspended`).                 | string | n/a     | yes          |
| transfer_acceleration              | Transfer Acceleration status (`Enabled` or `Suspended`).                     | string | n/a     | yes          |
| enable_logging                     | If true, creates a logging bucket and enables logging.                       | bool   | false   | no           |
| tag_Environment                    | Environment tag value.                                                      | string | n/a     | yes          |
| tag_Project_Name                   | Project name tag value.                                                     | string | n/a     | yes          |
| tag_Team                           | Team tag value.                                                             | string | n/a     | yes          |
| tag_Owner                          | Owner tag value.                                                            | string | n/a     | yes          |
| lock_object                        | Enable S3 Object Lock (WORM). Requires versioning.                          | bool   | false   | no           |
| object_lock_mode                   | Object Lock mode (`GOVERNANCE` or `COMPLIANCE`). Required if `lock_object`. | string | n/a     | conditional  |
| years                              | Retention duration in years. Required if `lock_object`.                     | number | n/a     | conditional  |
| block_acls                         | Block new public ACLs.                                                      | bool   | true    | no           |
| block_policy                       | Block public bucket policies.                                               | bool   | true    | no           |
| ignore_acls                        | Ignore public ACLs.                                                         | bool   | true    | no           |
| restrict_buckets                   | Restrict public access.                                                     | bool   | true    | no           |
| enable_life_cycle_rules            | Enable lifecycle configuration.                                             | bool   | false   | no           |
| object_prefix                      | Object key prefix filter for lifecycle rules.                               | string | n/a     | conditional  |
| object_tag                         | Object tag filter for lifecycle rules.                                      | string | n/a     | conditional  |
| current_transition_days            | Days before transition of current object version.                           | number | n/a     | conditional  |
| current_transition_storage_class   | Storage class for current object transition (e.g., `STANDARD_IA`).          | string | n/a     | conditional  |
| current_expiration_days            | Days before expiration of current object version.                           | number | n/a     | conditional  |
| non_current_transition_days        | Days before transition of noncurrent versions.                              | number | n/a     | conditional  |
| non_current_transition_storage_class | Storage class for noncurrent version transition (e.g., `GLACIER`).         | string | n/a     | conditional  |
| non_current_expiration_days        | Days before expiration of noncurrent versions.                              | number | n/a     | conditional  |
| enable_encryption                  | Enable server-side encryption.                                              | bool   | false   | no           |
| sse_algorithm                      | Encryption algorithm (`AES256` or `aws:kms`).                               | string | n/a     | conditional  |
| kms_key_arn                        | ARN of KMS Key if using `aws:kms`.                                          | string | ""      | no           |
| website_enable                     | Enable static website hosting.                                              | bool   | false   | no           |
| key_prefix_equals                  | Prefix for routing rule (website hosting).                                  | string | n/a     | conditional  |
| replace_key_prefix_with            | Replacement prefix for routing rule (website hosting).                      | string | n/a     | conditional  |


## 🗂️ Architecture Diagram

```text
                +----------------------+
                |   AWS Account        |
                |  (Caller Identity)   |
                +----------+-----------+
                           |
                           v
                +----------------------+
                |   Logging Bucket     |
                |  (optional)          |
                +----------+-----------+
                           |
                           |  Bucket Policy allows
                           |  logging.s3.amazonaws.com
                           v
                +----------------------+
                |   Main S3 Bucket     |
                |----------------------|
                | - Versioning         |
                | - Object Lock        |
                | - Ownership Controls |
                | - Lifecycle Rules    |
                | - Encryption (SSE)   |
                | - Public Access Block|
                | - Transfer Accel.    |
                | - Website Hosting    |
                +----------+-----------+
                           |
                           v
                +----------------------+
                |   Website Endpoint   |
                |  index.html / error.html
                |  Routing rules (docs/ → documents/)
                +----------------------+
