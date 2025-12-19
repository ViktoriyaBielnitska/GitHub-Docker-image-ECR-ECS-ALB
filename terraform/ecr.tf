data "aws_ecr_repository" "nginx" {
  name = "nginx-hello"
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.nginx.repository_url
}
