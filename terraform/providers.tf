// Used to configure credentials for providers
data "aws_availability_zones" "available" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.64"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region  = var.aws-config.region
  profile = var.aws-config.profile

  default_tags {
    tags = var.common-tags
  }
}
