provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Lab3-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Lab3-IGW"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}b"
  tags = {
    Name = "Private-Subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Web Server
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH from anywhere"
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
  
  tags = {
    Name = "Web-Security-Group"
  }
}

# EC2 Instance - Web Server (with correct AMI)
resource "aws_instance" "web_server" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Lab 3 - Part 1 Complete</h1>" > /var/www/html/index.html
              echo "<p>Deployed with Terraform</p>" >> /var/www/html/index.html
              EOF
  
  tags = {
    Name    = "Lab3-Web-Server"
    Project = "SYST53364-Lab3"
  }
}

# AWS Secrets Manager - Database Password
resource "aws_secretsmanager_secret" "db_secret" {
  name = "lab3/database/password"
  description = "Database credentials for Lab 3"
  
  tags = {
    Project = "SYST53364-Lab3"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "db_admin"
    password = "ExamplePassword123!"
    note     = "This is a sample secret for Lab 3"
  })
}

# Output values
output "web_server_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP address of the web server"
}

output "web_server_url" {
  value       = "http://${aws_instance.web_server.public_ip}"
  description = "URL to access the web server"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}
