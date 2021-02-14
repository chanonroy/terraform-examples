terraform {
  required_providers {
    aws = {
       source  = "hashicorp/aws"
       version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# The tutorial already has setup a VPC and two subnets.

# Find the VPC id
data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = ["LinuxAcademy"]
  }
}

# Find the first subnet id
data "aws_subnet" "us-east-1e" {
  availability_zone = "us-east-1e"
}

# data "aws_subnet" "us-east-1d" {
#   availability_zone = "us-east-1d"
# }

# Create EC2 instances
resource "aws_instance" "host1" {
  ami                         = "ami-047a51fa27710816e" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.us-east-1e.id
  security_groups             = [aws_security_group.sg.id]
  key_name                    = var.key_pair_name
  user_data = <<EOT
    yum update -y
    yum install -y httpd
    cp /usr/share/httpd/noindex/index.html /var/www/html/index.html
    service httpd start
  EOT

  tags = {
    Name = "Host1"
  }
}

# Add Security Group
resource "aws_security_group" "SG" {
  name        = "SG"
  description = "Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "All traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ATD_Bastion-SG"
  }
}
