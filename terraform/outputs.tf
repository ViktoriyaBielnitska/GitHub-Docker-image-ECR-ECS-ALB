output "ecr_repository_url" {
  value = aws_ecr_repository.nginx.repository_url
}
output "alb_dns_name" {
  value = data.aws_lb.existing_alb.dns_name
}
output "ecs_cluster_arn" {
  value = data.aws_ecs_cluster.existing.arn
}
output "public_subnets" {
  value = data.aws_subnets.public.ids
}
output "alb_security_group_id" {
  value = data.aws_security_group.alb_sg.id
}

