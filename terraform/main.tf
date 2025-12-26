############################
# DATA
############################
data "aws_availability_zones" "available" {}

############################
# VPC
############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.project_name
  cidr = "10.0.0.0/16"

  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
}

############################
# SECURITY GROUPS
############################
# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-ecs"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# ECR
############################
resource "aws_ecr_repository" "nginx" {
  name                 = "${var.project_name}-nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

############################
# ECS CLUSTER
############################
resource "aws_ecs_cluster" "main" {
  name = var.project_name
}

############################
# ALB
############################
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
  internal           = false
}

resource "aws_lb_target_group" "ecs" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################
# ECS SERVICE (EC2, без окремого Task Definition)
############################
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.7"

  name         = "nginx"
  cluster_arn  = aws_ecs_cluster.main.arn
  launch_type  = "EC2"
  network_mode = "bridge"

  cpu           = 256
  memory        = 512
  desired_count = 1

  container_definitions = {
    nginx = {
      image = "${aws_ecr_repository.nginx.repository_url}:latest"
      port_mappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.ecs.arn
      container_name   = "nginx"
      container_port   = 80
    }
  }

  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.ecs_sg.id]

  depends_on = [aws_lb_listener.http]
}
