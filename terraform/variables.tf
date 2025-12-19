variable "aws_region" {
  default = "us-east-1"
}
variable "ecs_instance_type" {
  default = "t3.micro"
}
variable "desired_capacity" {
  type    = number
  default = 1
}