module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.10.0"

  cluster_name = "ecs-ec2"
}
# ECS optimized AMI
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

}
# -------------------
# ALB (official ALB module)
# -------------------
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.17.0" # остання стабільна версія

  name                       = "my-alb"
  internal                   = false
  subnets                    = module.vpc.public_subnets
  security_groups            = []
  enable_deletion_protection = false
}
