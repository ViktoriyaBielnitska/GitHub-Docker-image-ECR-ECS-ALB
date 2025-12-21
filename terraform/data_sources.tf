##########################
# DATA SOURCES
##########################

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_lb" "existing_alb" {
  name = "nginx-alb"
}

data "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
}

data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
}

data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }
}