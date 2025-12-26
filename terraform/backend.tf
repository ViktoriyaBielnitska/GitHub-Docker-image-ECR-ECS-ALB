terraform {
  backend "s3" {
    bucket  = "ecs-nginx-hello-terraform-state"
    key     = "ecs-nginx-hello/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
