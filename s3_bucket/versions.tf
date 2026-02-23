terraform {
  required_version = "~> 1.13.0"
  required_providers {
    aws = {
        version = "~> 6.10.0"
        source = "hashicorp/aws"
    }
  }
}