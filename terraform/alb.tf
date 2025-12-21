resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.nginx.arn
  }

  depends_on = [data.aws_lb_target_group.nginx]
}
