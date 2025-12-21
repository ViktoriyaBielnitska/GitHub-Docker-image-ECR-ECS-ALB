data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_ecs_cluster" "existing" {
  cluster_name = "nginx-ecs-cluster"
}

data "aws_ecr_repository" "nginx" {
  name = "nginx-hello"
}

data "aws_security_group" "alb_sg" {
  filter {
    name   = "group-name"
    values = ["alb-sg"]
  }

  vpc_id = var.vpc_id
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
