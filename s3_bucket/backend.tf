terraform {
  backend "s3" {
    bucket = "ochirdorj-terraform-backend-bucket"
    key = "infra/example_s3_bucket/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}