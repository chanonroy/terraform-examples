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

# Create a VPC
resource "aws_vpc" "atd_vpc" {
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "ATD_VPC"
  }
}

# Create Our Subnets
resource "aws_subnet" "atd_public1" {
  vpc_id            = aws_vpc.atd_vpc.id
  cidr_block        = "192.168.0.0/26"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ATD_Public1"
  }
}

resource "aws_subnet" "atd_public2" {
  vpc_id            = aws_vpc.atd_vpc.id
  cidr_block        = "192.168.0.64/26"
  availability_zone = "us-east-1b"

  tags = {
    Name = "ATD_Public2"
  }
}

resource "aws_subnet" "atd_private3" {
  vpc_id            = aws_vpc.atd_vpc.id
  cidr_block        = "192.168.0.128/26"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ATD_Private3"
  }
}

resource "aws_subnet" "atd_private4" {
  vpc_id            = aws_vpc.atd_vpc.id
  cidr_block        = "192.168.0.192/26"
  availability_zone = "us-east-1b"

  tags = {
    Name = "ATD_Private4"
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "atd_igw" {
  vpc_id = aws_vpc.atd_vpc.id

  tags = {
    Name = "ATD_IGW"
  }
}

# Create Public and Private Route Tables
resource "aws_route_table" "atd_publicrt" {
  vpc_id = aws_vpc.atd_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.atd_igw.id
  }

  tags = {
    Name = "ATD_PublicRT"
  }
}

resource "aws_route_table_association" "atd_publicrt_subnet_1" {
  subnet_id      = aws_subnet.atd_public1.id
  route_table_id = aws_route_table.atd_publicrt.id
}

resource "aws_route_table_association" "atd_publicrt_subnet_2" {
  subnet_id      = aws_subnet.atd_public2.id
  route_table_id = aws_route_table.atd_publicrt.id
}

resource "aws_route_table" "atd_privatert" {
  vpc_id = aws_vpc.atd_vpc.id

  tags = {
    Name = "ATD_PrivateRT"
  }
}

resource "aws_route_table_association" "atd_privatert_subnet_1" {
  subnet_id      = aws_subnet.atd_private3.id
  route_table_id = aws_route_table.atd_privatert.id
}

resource "aws_route_table_association" "atd_privatert_subnet_2" {
  subnet_id      = aws_subnet.atd_private4.id
  route_table_id = aws_route_table.atd_privatert.id
}

# Configure a NACL
resource "aws_network_acl" "atd_public1" {
  vpc_id = aws_vpc.atd_vpc.id
  # The subnet associations
  subnet_ids = [aws_subnet.atd_public1.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "${var.my_ip}/32"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "${var.my_ip}/32"
    from_port  = 1024
    to_port    = 65535
  }

  # Added second set of ingress/egress after bastion host created
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "192.168.0.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "192.168.0.0/24"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "ATD_Public1"
  }
}

# Security Groups
resource "aws_security_group" "atd_bastion" {
  name        = "ATD_Bastion-SG"
  description = "ATD_Bastion-SG"
  vpc_id      = aws_vpc.atd_vpc.id

  ingress {
    description = "RemoteAdmin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  # Added in after bastion host created
  egress {
    description = "SSH to AppServers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }

  tags = {
    Name = "ATD_Bastion-SG"
  }
}

# Configure the Bastion Host
resource "aws_instance" "bastion_host" {
  ami                         = "ami-047a51fa27710816e" # Amazon Linux 2 AMI
  key_name                    = "atd_keypair"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.atd_public1.id
  security_groups             = [aws_security_group.atd_bastion.id]

  tags = {
    Name = "BastionHost"
  }
}

### NOTE: Download the keypair from the UI yourself, not practical to generate one here

# Allow Traffic from the Bastion Host to the Application Servers
## Went back to aws_security_group.atd_bastion and added new egress
## Went back to aws_network_acl.atd_public1 and added new ingress/egress

# Private3 Setup
resource "aws_network_acl" "atd_private_3" {
  vpc_id     = aws_vpc.atd_vpc.id
  subnet_ids = [aws_subnet.atd_private3.id, aws_subnet.atd_private4.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    from_port  = 22
    to_port    = 22
    cidr_block = "192.168.0.0/26"
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 120
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = "110"
    action     = "allow"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    protocol   = "icmp"
    rule_no    = "120"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
  }

  tags = {
    Name = "ATD_Private3"
  }
}
