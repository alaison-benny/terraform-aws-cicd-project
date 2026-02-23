# --- Day 4: High Availability & CI/CD Portfolio Deployment ---

# 1. VPC & Networking
resource "aws_vpc" "day3_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Day3-VPC" }
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.day3_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = { Name = "Subnet-2a" }
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.day3_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = { Name = "Subnet-2b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.day3_vpc.id
  tags   = { Name = "Day3-IGW" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.day3_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}

# 2. Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.day3_vpc.id

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

# 3. Load Balancer Configuration
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.day3_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# 4. Launch Template with AI Portfolio User Data
resource "aws_launch_template" "web_config" {
  name_prefix   = "web-server-template"
  image_id      = "ami-09040d770ffe2224f" 
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.alb_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nginx git
              sudo rm -rf /var/www/html/*
              echo "<html><body style='background-color:#1a1a1a; color:white; text-align:center; padding-top:50px; font-family:sans-serif;'>
                    <h1 style='color:#007bff;'>Alaison's AI Portfolio</h1>
                    <p>Compliance-Led AI Cloud Engineer In Training</p>
                    <hr style='width:50%; border:0.5px solid #333;'>
                    <div style='color:#00ff00; font-weight:bold;'>Deployment via GitHub Actions: SUCCESSFUL</div>
                    <p style='font-size: small; color: #888;'>Auto-scaled & Load-balanced Infrastructure</p>
                    </body></html>" > /var/www/html/index.html
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  )
}

# 5. Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  vpc_zone_identifier = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.web_config.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "ASG-Web-Server"
    propagate_at_launch = true
  }
}

# 6. Outputs
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}