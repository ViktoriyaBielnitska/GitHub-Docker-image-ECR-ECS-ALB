resource "aws_ecs_cluster" "nginx" {
  name = "nginx-ecs-cluster"
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.nginx.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = data.aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_attachment.ecs_alb_attachment]
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = data.aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = data.aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##########################
# ECS Launch Template
##########################
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }
}

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
# ECS Auto Scaling Group
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


  # Опціонально: Target Group для ALB
  # target_group_arns = [aws_lb_target_group.nginx.arn]

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

resource "aws_autoscaling_attachment" "ecs_alb_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  lb_target_group_arn    = data.aws_lb_target_group.nginx.arn

}
