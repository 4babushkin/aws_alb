### main
variable aws_access_key {
  description = "AWS Access key:"
}

variable aws_secret_key {
  description = "AWS Secret key:"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/id_rsa.pub"
}


variable aws_region {
  default = "eu-west-1"
}


#####
variable min_autoscaling_size {
  description = "The minimum size of the auto scale group."
  default     = 2
}

variable max_autoscaling_size {
  description = "The maximum size of the auto scale group"
  default     = 5
}

variable image_id {
  description = "The EC2 Ubuntu image ID to launch"
  default     = "ami-0823c236601fef765"
}
