output "alb_dns_name" {
  value = data.aws_lb.existing_alb.dns_name
}

output "ecs_cluster_arn" {
  value = data.aws_ecs_cluster.existing.arn
}

output "ecr_repository_url" {
  value       = data.aws_ecr_repository.nginx.repository_url
  description = "URL існуючого ECR репозиторію"
}


