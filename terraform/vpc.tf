#############################################################################
# VPC - create aws_vpc
############################################################################

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "My VPC"
  }
}

resource "aws_subnet" "public_zone_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Public Subnet ${var.aws_region}a"
  }
}

resource "aws_subnet" "public_zone_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Public Subnet ${var.aws_region}b"
  }
}

resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My VPC - Internet Gateway"
  }
}

resource "aws_route_table" "my_vpc_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_vpc_igw.id
  }

  tags = {
    Name = "Public Subnets Route Table for My VPC"
  }
}

resource "aws_route_table_association" "my_vpc_us_east_1a_public" {
  subnet_id      = aws_subnet.public_zone_1a.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_route_table_association" "my_vpc_us_east_1b_public" {
  subnet_id      = aws_subnet.public_zone_1b.id
  route_table_id = aws_route_table.my_vpc_public.id
}

#############################################################################
# FAERWALL
############################################################################


resource "aws_security_group" "alb" {
  name   = "terraform-alb-security-group"
  vpc_id = aws_vpc.my_vpc.id

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
  name   = "terraform-instance-security-group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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
