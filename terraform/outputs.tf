variable "aws_region" {
  type    = string
  default = "us-east-1"
}

output "ecr_url" {
  value = aws_ecr_repository.nginx.repository_url
}
