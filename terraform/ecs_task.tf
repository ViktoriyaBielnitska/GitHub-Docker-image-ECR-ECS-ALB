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
      image     = "386930771365.dkr.ecr.us-east-1.amazonaws.com/nginx-hello:latest"
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