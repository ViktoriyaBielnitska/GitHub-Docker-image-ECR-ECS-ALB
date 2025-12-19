resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-hello"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "128"
  memory                   = "256"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "${data.aws_ecr_repository.nginx.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}
