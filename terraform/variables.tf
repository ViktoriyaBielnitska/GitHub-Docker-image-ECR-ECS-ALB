variable "project_name" {
  type    = string
  default = "ecs-nginx-hello-terraform"
}
variable "github_org" {
  type        = string
  description = "GitHub organization or username"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}
