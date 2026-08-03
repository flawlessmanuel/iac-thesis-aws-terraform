# provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use the region variable defined in variables.tf
provider "aws" {
  region = var.aws_region
}