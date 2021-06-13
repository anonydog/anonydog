provider "aws" {
  region = local.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}