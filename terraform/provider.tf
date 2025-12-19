terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.aws_region
}
