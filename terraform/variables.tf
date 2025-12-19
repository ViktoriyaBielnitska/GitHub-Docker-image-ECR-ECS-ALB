variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0550fe5101865d5da"
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "ecs_instance_type" {
  type    = string
  default = "t2.micro"
}
