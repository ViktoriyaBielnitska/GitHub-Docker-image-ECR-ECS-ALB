resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-hello"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "128"
  memory                   = "256"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/c5l2w2r3/nginx-hello:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
        }
      ]
    }
  ])
}