module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.10.0"

  cluster_name = "ecs-ec2"
}

module "ecs_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.0"

  name = "ecs-asg"

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = module.vpc.public_subnets
  image_id            = data.aws_ami.ecs.id
  instance_type       = "t3.micro"

  user_data = base64encode("echo ECS_CLUSTER=ecs-ec2 >> /etc/ecs/ecs.config")
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
# terraform/aws_cloudwatch.tf
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/aws/ecs/ecs-ec2"
  retention_in_days = 7   # можна змінити за потреби
}

