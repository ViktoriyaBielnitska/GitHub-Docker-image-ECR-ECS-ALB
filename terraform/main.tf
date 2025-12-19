# -------------------
# ECS Cluster EC2 (official ECS module)
# -------------------
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"


  cluster_name = "ecs-ec2"

}

module "ecs_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = "ecs-asg"

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = module.vpc.public_subnets
  image_id            = data.aws_ami.ecs.id
  instance_type       = "t3.micro"

  user_data = base64encode("echo ECS_CLUSTER=ecs-ec2 >> /etc/ecs/ecs.config")
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
  version = "~> 9.0"
}