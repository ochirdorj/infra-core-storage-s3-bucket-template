variable "enable_logging" {
  type = bool
  description = "true = enable logging, false = disable logging"
}

variable "bucket_name" {
  type = string
  description = "Name of the bucket"  
}

variable "lock_object" {
  type = bool
  description = "Choose object lock true or false"
}

variable "tag_Environment" {
  type = string
  description = "Environment"
}

variable "tag_Managed_By" {
  type = string
  description = "Name of the tool"
}

variable "tag_Project" {
  type = string
  description = "Project name"
}

variable "tag_Team" {
  type = string
  description = "Team"
}

variable "tag_Owner" {
  type = string
  description = "Owner"
}

variable "object_lock_mode" {
  type = string
  description = "Strong protection mode. Even root user is unable to delete the object. Make it COMPLIANCE or GOVERNANCE, delete the resource if you don't want retention"
}

variable "years" {
  type = string
  description = "Object lock retention year"
}

variable "block_acls" {
  type = bool
  description = "true or false in block public acls"
}

variable "block_policy"{
  type = bool
description = "true or false in block public policy"
}

variable "ignore_acls"{
  type = bool
  description = "true or false in ignore public acls"
}

variable "restrict_buckets" {
  description = "true or false restrict public buckets"
}

variable "enable_life_cycle_rules" {
  type = bool
  description = "true = enable or false = disable lifecycel policy"
}

variable "object_prefix" {
  type = string
  description = "This is object prefix. Use it when you apply lifecycle rule to the object"
}

variable "object_tag" {
  type = string
  description = <<EOT
  "This object tag. Use it when you apply lifecycle rule to the object.
   Keep in mine object tag and object prefix both needed to be satisfied in order to apply lifecycle rule"
   EOT
}

variable "current_transition_days" {
  type = number
  description = "number of days after current object to transit different storage class"
}

variable "current_transition_storage_class" {
  type = string
  description = <<EOT
  "transition storage type of current object. Choose one of STANDARD, STANDARD_IA, ONEZONE_IA,
   INTELLIGENT_TIERING, DEEP_ARCHIVE, REDUCED_REDUNDANCY"
   EOT
}

variable "current_expiration_days" {
  type = number
  description = "The number of days after which the current object version will be permanently deleted"
}

variable "non_current_transition_days" {
  type = string
  description = "number of days after non current object to transit different storage class"
}

variable "non_current_transition_storage_class" {
  type = string
  description = <<EOT
  "non current object will transit to this storage class. choose one of STANDARD, STANDARD_IA, ONEZONE_IA,
   INTELLIGENT_TIERING, DEEP_ARCHIVE, REDUCED_REDUNDANCY"
   EOT
}

variable "non_current_expiration_days" {
  type = number
  description = "The number of days after which the non current object version will be permanently deleted"
}

variable "bucket_versioning_status" {
  type = string
  description = "Configuration of versioning. Make is Enabled or Suspended"
}

variable "enable_encryption" {
  type = bool
  description = "true encryption enabled, false encryption disabled"
}

variable "sse_algorithm" {
  type = string
  description = "choose aws:kms , AES256, "
}

variable "kms_key_arn" {
  type = string
  description = "enter kms cumtomer managed key arn"
}

variable "transfer_acceleration" {
  type = string
  description = "Enable or Suspended transfer acceleration"
}

variable "website_enable" {
  type = bool
  description = "Static website hosting. Enable = true, Disable = false"
}

variable "key_prefix_equals" {
  type = string
  description = <<EOT
  "The object key prefix used as a condition for the routing rule. Requests with keys
   starting with this prefix will trigger the redirect"
   EOT
}

variable "replace_key_prefix_with" {
  type = string
  description = <<EOT
  "The new key prefix that replaces the matched prefix in the redirect. 
  Requests matching the condition will be redirected to this prefix."
  EOT
}