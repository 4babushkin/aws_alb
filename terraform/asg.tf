
resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh_key_${var.aws_region}"
  public_key = file(var.public_key_path)
}

#############################################################################
# AutoScaling Group
#############################################################################

# UBUNTU
resource "aws_autoscaling_group" "ubuntu-ec2" {
  launch_configuration = aws_launch_configuration.ubuntu-ec2.name
  vpc_zone_identifier  = [aws_subnet.public_zone_1a.id, aws_subnet.public_zone_1b.id]

  # Включаем интеграцию между ASG и ALB, указав аргумент target_group_arns
  # на целевую группу aws_lb_target_group.asg-target_group.arn,
  # чтобы целевая группа знала, в какие инстансы EC2 отправлять запросы.
  target_group_arns = [aws_lb_target_group.asg-target-group.arn]
  health_check_type = "ELB"

  min_size = var.min_autoscaling_size
  max_size = var.max_autoscaling_size

  tag {
    key                 = "Name"
    value               = "terraform-asg-ubuntu-ec2"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "ubuntu-ec2" {
  lifecycle { create_before_destroy = true }
  image_id      = var.image_id
  instance_type = "t2.micro"

  security_groups             = [aws_security_group.instance.id]
  key_name                    = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  user_data                   = <<-EOF
#!/bin/bash
apt-get update && apt-get install git ansible -y;
#pip install ansible;
git clone https://github.com/4babushkin/aws_alb /tmp/aws_alb;
HOME=/root /usr/bin/ansible-playbook -i /tmp/aws_alb/ansible/hosts /tmp/aws_alb/ansible/site.yml -vvv &> /tmp/ansible.log;
    EOF
}
