#############################################################################
# ALB (Application Load Balancer)
#############################################################################

# name — name
# load_balancer_type — type balancer.
# subnets — VPC default
# security_groups — aws_security_group.instance

resource "aws_lb" "alb" {
  name               = "terraform-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_zone_1a.id, aws_subnet.public_zone_1b.id]
  security_groups    = [aws_security_group.alb.id]
}

# Создание listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg-listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg-target-group.arn
  }
}

# aws_lb_target_group for ASG.
resource "aws_lb_target_group" "asg-target-group" {
  name     = "terraform-aws-lb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
