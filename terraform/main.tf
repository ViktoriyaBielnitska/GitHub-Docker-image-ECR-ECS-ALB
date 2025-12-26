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
module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name   = "${var.project_name}-ecs"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.alb_sg.id
    }
  ]

  egress_rules = ["all-all"]
}

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
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.7"

  cluster_name = var.project_name
}

############################
# APPLICATION LOAD BALANCER
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
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  depends_on        = [aws_lb_target_group.ecs]
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

############################
# ECS SERVICE (EC2)
############################
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.7"

  name         = "nginx"
  cluster_arn  = module.ecs.cluster_arn
  launch_type  = "EC2"
  network_mode = "awsvpc"

  cpu    = 256
  memory = 512

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
  security_group_ids = [module.ecs_sg.security_group_id]
}
