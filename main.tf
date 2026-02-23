terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0" # പുതിയ വേർഷൻ നിർബന്ധമാക്കുന്നു
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# --- ബാക്കെൻഡ് റിസോഴ്സുകൾ (ഇത് ഒഴിവാക്കരുത്) ---
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "alaison-terraform-state-2026"
  force_destroy = false
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# --- VPC & Networking ---
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
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.day3_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.day3_vpc.id
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

# --- Security & Load Balancer ---
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

# --- Launch Template & Auto Scaling ---
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

              # പഴയ ഫയലുകൾ മാറ്റുന്നു
              sudo rm -rf /var/www/html/*

              # നിങ്ങളുടെ ഗിറ്റഹബ്ബ് റിപ്പോസിറ്ററിയിൽ നിന്ന് ഫയലുകൾ ക്ലോൺ ചെയ്യുന്നു
              git clone https://github.com/alaison-benny/terraform-aws-cicd-project.git /tmp/website
              
              # ഫയലുകൾ ശരിയായ സ്ഥലത്തേക്ക് മാറ്റുന്നു
              sudo cp -r /tmp/website/index.html /var/www/html/
              sudo cp -r /tmp/website/styles.css /var/www/html/
              sudo cp -r /tmp/website/profile.jpg /var/www/html/ # ചിത്രത്തിന്റെ പേര് ശ്രദ്ധിക്കുക

              sudo systemctl restart nginx
              EOF
  )
}

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
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}