locals {
  ami = "ami-1dab2163"
}

provider "aws" {
  profile = "kubernetes"
  region  = "eu-north-1"
}

resource "aws_vpc" "test" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false
  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "test" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "test"
  }
}

resource "aws_default_security_group" "test" {
  vpc_id = aws_vpc.test.id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "test"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id
  tags = {
    Name = "test"
  }
}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }
  tags = {
    Name = "test"
  }
}

resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.test.id
}

resource "aws_instance" "master" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test.id
  vpc_security_group_ids = [aws_default_security_group.test.id]
  key_name               = "ssh-key"
  tags = {
    Name = "master"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.master.public_ip} > public_master_ip"
  }
}