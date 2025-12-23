# ECS CLUSTER
resource "aws_ecs_cluster" "nginx" {
  name = "nginx-ecs-cluster"
}

# SECURITY GROUPS
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-${random_id.sg_suffix.hex}"
  description = "Allow traffic from ALB"
  vpc_id      = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "allow_alb_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = data.aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "allow_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

# ECS TASK DEFINITION
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-hello"
  network_mode             = "awsvpc" # Ключова зміна
  requires_compatibilities = ["EC2"]
  cpu                      = "128"
  memory                   = "256"

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "386930771365.dkr.ecr.us-east-1.amazonaws.com/nginx-hello:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/nginx"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# TARGET GROUP
resource "aws_lb_target_group" "nginx" {
  name        = "nginx-tg-${random_id.tg_suffix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip" # Ключова зміна

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB
resource "aws_lb" "nginx_alb" {
  name               = "nginx-alb-${random_id.lb_suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids
}

# ALB LISTENER
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# ECS SERVICE
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service-${random_id.ecs_svc.hex}"
  cluster         = aws_ecs_cluster.nginx.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.http
  ]
}
# RANDOM IDS FOR UNIQUE NAMES
resource "random_id" "lb_suffix" {
  byte_length = 2
}

resource "random_id" "tg_suffix" {
  byte_length = 2
}

resource "random_id" "ecs_svc" {
  byte_length = 2
}

resource "random_id" "sg_suffix" {
  byte_length = 2
}
