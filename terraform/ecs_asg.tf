##########################
# RANDOM IDS FOR UNIQUE NAMES
##########################
resource "random_id" "lb_suffix" {
  byte_length = 2
}

resource "random_id" "tg_suffix" {
  byte_length = 2
}

resource "random_id" "ecs_svc" { # <- додано для унікального ECS сервісу
  byte_length = 2
}

##########################
# IAM POLICIES
##########################
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = data.aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = data.aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##########################
# ECS CLUSTER
##########################
resource "aws_ecs_cluster" "nginx" {
  name = "nginx-ecs-cluster"
}

##########################
# LAUNCH TEMPLATE
##########################
resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-lt-"
  image_id      = data.aws_ami.ecs.id
  instance_type = var.ecs_instance_type

  iam_instance_profile {
    name = data.aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.nginx.name} >> /etc/ecs/ecs.config
EOF
  )
}

##########################
# TARGET GROUP
##########################
resource "aws_lb_target_group" "nginx" {
  name     = "nginx-tg-${random_id.tg_suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

##########################
# ALB
##########################
resource "aws_lb" "nginx_alb" {
  name               = "nginx-alb-${random_id.lb_suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids
}

##########################
# ALB LISTENER
##########################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

##########################
# AUTO SCALING GROUP
##########################
resource "aws_autoscaling_group" "ecs" {
  desired_capacity    = var.desired_capacity
  min_size            = var.desired_capacity
  max_size            = var.desired_capacity
  vpc_zone_identifier = data.aws_subnets.public.ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.nginx.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 60
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }
}

##########################
# ECS TASK DEFINITION
##########################
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-hello"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "128"
  memory                   = "256"

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "386930771365.dkr.ecr.us-east-1.amazonaws.com/nginx-hello:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

##########################
# ECS SERVICE
##########################
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service-${random_id.ecs_svc.hex}"
  cluster         = aws_ecs_cluster.nginx.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_autoscaling_group.ecs,
    aws_lb_listener.http
  ]
}
