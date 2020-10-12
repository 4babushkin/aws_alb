terraform {
  # Версия terraform
  required_version = ">=0.12,<0.13"
}

#############################################################################
# WHICH PROVIDER.  AND REGION
#############################################################################
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
  version    = "~> 3.0"
}


#############################################################################
# VPC -default
############################################################################

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Найти в VPC-подсетях Default VPC.
data "aws_vpc" "default" {
  default = true
}

#############################################################################
# FAERWALL
############################################################################


resource "aws_security_group" "alb" {
  name = "terraform-alb-security-group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# this security_group to aws_launch_configuration
resource "aws_security_group" "instance" {
  name = "terraform-instance-security-group"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#############################################################################
# ALB (Application Load Balancer)
#############################################################################

# name — name
# load_balancer_type — tipe balancer.
# subnets — VPC default
# security_groups — aws_security_group.instance

resource "aws_lb" "alb" {
  name               = "terraform-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# Создание listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # Страница 404 если будут запросы, которые не соответствуют никаким правилам прослушивателя.
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: страница не найдена"
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
  vpc_id   = data.aws_vpc.default.id

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


#############################################################################
# instances
#############################################################################

# UBUNTU
resource "aws_autoscaling_group" "ubuntu-ec2" {
  launch_configuration = aws_launch_configuration.ubuntu-ec2.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  # Включаем интеграцию между ASG и ALB, указав аргумент target_group_arns
  # на целевую группу aws_lb_target_group.asg-target_group.arn,
  # чтобы целевая группа знала, в какие инстансы EC2 отправлять запросы.
  target_group_arns = [aws_lb_target_group.asg-target-group.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key                 = "Name"
    value               = "terraform-asg-ubuntu-ec2"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "ubuntu-ec2" {
  lifecycle { create_before_destroy = true }
  image_id      = "ami-0823c236601fef765"
  instance_type = "t2.micro"

  security_groups             = [aws_security_group.instance.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = <<-EOF
#!/bin/bash
apt-get update && apt-get install git ansible -y;
#pip install ansible;
git clone https://github.com/4babushkin/aws_alb /tmp/aws_alb;
HOME=/root /usr/bin/ansible-playbook -i /tmp/aws_alb/ansible/hosts /tmp/aws_alb/ansible/site.yml -vvv &> /tmp/ansible.log;
    EOF
}


#############################################################################
# DNS ALB
############################################################################

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "ALB Domain name"
}
