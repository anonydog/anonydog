terraform {
  required_providers {
    vercel = {
      source = "chronark/vercel"
      version = "= 0.14.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.40.0"
    }
    archive = {
      source = "archive"
      version = "~> 2.2.0"
    }
  }
  required_version = ">= 0.13"
}
