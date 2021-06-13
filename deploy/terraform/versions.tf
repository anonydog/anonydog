terraform {
  required_providers {
    wercel = {
      source = "thiagoarrais/wercel"
      version = "= 0.1.1"
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
