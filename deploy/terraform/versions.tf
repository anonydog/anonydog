terraform {
  required_providers {
    wercel = {
      source = "thiagoarrais/wercel"
      version = "= 0.1.1"
    }
    aws = {
      source = "hashicorp/aws"
      version = "3.26.0"
    }
  }
  required_version = ">= 0.13"
}
