provider "aws" {
  region = var.region
}

# VPC (keep as is)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "Lab3-VPC" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "Lab3-IGW" }
}

# Public Subnets (2 for Multi-AZ)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-A" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-B" }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-RT" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  
  ingress {
    description = "SSH"
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
  
  tags = { Name = "Web-SG" }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTP to ALB"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP"
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
  
  tags = { Name = "ALB-SG" }
}

# Load Balancer
resource "aws_lb" "web_lb" {
  name               = "lab3-lb-20260131124539"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = { Name = "Lab3-ALB" }
}

# Target Group - USE SIMPLE HEALTH CHECK TO "/"
resource "aws_lb_target_group" "web_tg" {
  name     = "lab3-tg-20260131124539"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  # SIMPLE health check - just check root path
  health_check {
    enabled             = true
    path                = "/"  # Changed from "/health" to "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"  # Accept only 200 OK
  }
  
  tags = { Name = "Lab3-TG" }
}

# Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Launch Template with WORKING health check
resource "aws_launch_template" "web" {
  name_prefix   = "lab3-web-20260131124539-"
  image_id      = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = var.instance_type
  
  # SIMPLE User Data that ALWAYS works
  user_data = base64encode(<<-EOT
              #!/bin/bash
              
              # Install Apache
              yum update -y
              yum install -y httpd
              
              # Start Apache
              systemctl start httpd
              systemctl enable httpd
              
              # Create index.html (root path for health check)
              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html>
              <head><title>Lab 3 - Healthy Server</title></head>
              <body>
              <h1>Lab 3 - Part 2 Working!</h1>
              <p>This server is healthy and responding to health checks.</p>
              <p>Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
              <p><a href="/health.html">Health Check Page</a></p>
              </body>
              </html>
              HTML
              
              # Create health.html (simple HTML page)
              cat > /var/www/html/health.html << 'HEALTH'
              <!DOCTYPE html>
              <html>
              <body>
              <h1 style="color:green;">HEALTHY</h1>
              <p>Status: All checks passed</p>
              <p>Time: $(date)</p>
              </body>
              </html>
              HEALTH
              
              # Create health.txt (even simpler for load balancer)
              echo "healthy" > /var/www/html/health.txt
              
              # Graceful shutdown script
              cat > /usr/local/bin/graceful-shutdown.sh << 'SHUTDOWN'
              #!/bin/bash
              echo "Graceful shutdown started at $(date)" > /tmp/shutdown.log
              sleep 10
              systemctl stop httpd
              echo "Apache stopped at $(date)" >> /tmp/shutdown.log
              echo "Ready for termination" >> /tmp/shutdown.log
              SHUTDOWN
              
              chmod +x /usr/local/bin/graceful-shutdown.sh
              
              echo "Setup complete at $(date)" > /tmp/setup.log
              EOT
              )
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "Lab3-ASG-Instance"
      Project = "SYST53364"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name               = "lab3-asg-20260131124539"
  max_size           = var.max_size
  min_size           = var.min_size
  desired_capacity   = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns  = [aws_lb_target_group.web_tg.arn]
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # Lifecycle Hook
  initial_lifecycle_hook {
    name                 = "graceful-shutdown"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    heartbeat_timeout    = 300
    default_result       = "CONTINUE"
  }
  
  tag {
    key                 = "Name"
    value               = "Lab3-ASG-Instance"
    propagate_at_launch = true
  }
}

# Secrets Manager (keep from Part 1)
resource "aws_secretsmanager_secret" "db_secret" {
  name = "lab3/database/password"
}

resource "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({ password = "Example123" })
}

# Outputs
output "load_balancer_url" {
  value = "http://${aws_lb.web_lb.dns_name}"
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "target_group_arn" {
  value = aws_lb_target_group.web_tg.arn
}
