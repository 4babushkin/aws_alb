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
# DNS ALB
############################################################################

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "ALB Domain name"
}
