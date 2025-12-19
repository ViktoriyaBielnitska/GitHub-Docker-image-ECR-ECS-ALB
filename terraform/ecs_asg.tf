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

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${data.aws_ecs_cluster.existing.cluster_name} >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  desired_capacity    = var.desired_capacity
  min_size            = var.desired_capacity
  max_size            = var.desired_capacity
  vpc_zone_identifier = data.aws_subnets.public.ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  # Optional: target group для ALB
  # target_group_arns = [aws_lb_target_group.nginx.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 60
  force_delete              = true

  # Правильне визначення тегів
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