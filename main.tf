terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# --- Backend Configuration ---
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

# --- Security Groups ---
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

# --- Load Balancer ---
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg" {
  # പൈപ്പ്‌ലൈൻ എറർ ഒഴിവാക്കാൻ പഴയ പേര് തന്നെ നൽകുന്നു
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

# --- Launch Template ---
resource "aws_launch_template" "web_config" {
  name_prefix   = "luxury-cars-template-" 
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
              
              # നിലവിലുള്ള ഫയലുകൾ നീക്കം ചെയ്യുന്നു
              sudo rm -rf /var/www/html/*
              sudo rm -rf /tmp/website_temp

              # പുതിയ കോഡ് ഗിറ്റ്ഹബ്ബിൽ നിന്ന് എടുക്കുന്നു
              git clone https://github.com/alaison-benny/terraform-aws-cicd-project.git /tmp/website_temp
              
              # എല്ലാ ഫയലുകളും Nginx ഫോൾഡറിലേക്ക് കോപ്പി ചെയ്യുന്നു
              sudo cp -r /tmp/website_temp/* /var/www/html/

              # പെർമിഷൻ ശരിയാക്കുന്നു (ഇമേജുകൾ കാണാൻ ഇത് പ്രധാനമാണ്)
              sudo chmod -R 755 /var/www/html/
              sudo chown -R www-data:www-data /var/www/html/

              sudo systemctl restart nginx
              sudo systemctl enable nginx
              EOF
  )