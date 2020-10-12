# AWS Application Load Balancer  

# Terraform 

## Config

copy `terraform.tfvars.example` to `terraform.tfvars` and edit variables
```
cp terraform.tfvars.example terraform.tfvars
```

## Information

    main.tf       - Provider and output
    vpc.tf        - Create VPC with two public subnet in zone A and B
    asg.tf        - AutoScaling Group based on Ubuntu 18.04 image
    alb.tf        - Application Load Balancer
    variables.tf  - default variables

EC2 instance run this configuration которая настроена в aws_launch_configuration

```bash
#!/bin/bash
apt-get update && apt-get install git ansible -y;
git clone https://github.com/4babushkin/aws_alb /tmp/aws_alb;
HOME=/root /usr/bin/ansible-playbook -i /tmp/aws_alb/ansible/hosts /tmp/aws_alb/ansible/site.yml -vvv &> /tmp/ansible.log;
```

Запускается ansible-playbook в котором устанавливается docker engine и запускатеся docker-compose.yml файл

```
version: '2'
services:
  nginx:
    image: nginxdemos/nginx-hello:latest
    restart: always
    ports:
      - 8080:8080
```

## Launch instructions

Execute the following commands:

```
terraform init
terraform plan
terraform apply
```

Outputs
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = terraform-alb-937084837.eu-west-1.elb.amazonaws.com
```
