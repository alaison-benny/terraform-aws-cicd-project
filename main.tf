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

# --- Backend Resources (With Safety Lock) ---
resource "aws_s3_bucket" "terraform_state" {
  bucket = "alaison-terraform-state-2026"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
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
  name     = "web-tg-new"  # പേര് മാറ്റുക
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

  user_data = base64encode(<<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx git
sudo rm -rf /var/www/html/*
sudo rm -rf /tmp/website_temp
git clone https://github.com/alaison-benny/terraform-aws-cicd-project.git /tmp/website_temp
sudo cp -r /tmp/website_temp/* /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo systemctl restart nginx
sudo systemctl enable nginx
EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg-automated"
  vpc_zone_identifier = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.web_config.id
    version = "$Latest" 
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "Luxury-Car-Server"
    propagate_at_launch = true
  }
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
# 1. SNS Topic നിർമ്മിക്കുന്നു
resource "aws_sns_topic" "user_updates" {
  name = "infrastructure-updates"
}

# 2. ഇമെയിൽ സബ്സ്ക്രിപ്ഷൻ (നിങ്ങളുടെ ഇമെയിൽ ഇവിടെ നൽകുക)ok
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "alaisonbennyonline@gmail.com" # <--- ഇവിടെ നിങ്ങളുടെ ഇമെയിൽ നൽകുക
}

# 3. CloudWatch Alarm (ASG ഇൻസ്റ്റൻസ് മാറ്റങ്ങൾ നിരീക്ഷിക്കാൻ)
resource "aws_cloudwatch_metric_alarm" "asg_health_alarm" {
  alarm_name          = "asg-health-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "GroupDesiredCapacity"
  namespace           = "AWS/AutoScaling"
  period              = "60"
  statistic           = "Average"
  threshold           = "2" # 2-ൽ കൂടുതൽ ഇൻസ്റ്റൻസ് വന്നാൽ അലാറം അടിക്കും

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "This metric monitors ASG desired capacity"
  alarm_actions     = [aws_sns_topic.user_updates.arn]
}