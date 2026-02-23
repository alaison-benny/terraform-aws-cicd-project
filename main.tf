# 1. ബാക്കെൻഡിനുള്ള S3 ബക്കറ്റ്
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "alaison-terraform-state-2026" # പുതിയ ഒരു പേര് നൽകുക
  force_destroy = false # ഇത് പ്രധാനമാണ്, ബക്കറ്റ് ഡിലീറ്റ് ആകരുത്
}

# 2. സ്റ്റേറ്റ് ലോക്കിംഗിനുള്ള DynamoDB Table
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
# 1. VPC നിർമ്മിക്കുന്നു
resource "aws_vpc" "day3_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Day3-VPC" }
}

# 2. Availability Zone 1-ൽ ഒരു സബ്നെറ്റ് (us-east-2a)
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.day3_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = { Name = "Subnet-2a" }
}

# 3. Availability Zone 2-ൽ രണ്ടാമത്തെ സബ്നെറ്റ് (us-east-2b)
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.day3_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = { Name = "Subnet-2b" }
}

# 4. ഇന്റർനെറ്റ് ഗേറ്റ്‌വേ (സെർവറിന് പുറംലോകവുമായി ബന്ധപ്പെടാൻ)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.day3_vpc.id
  tags   = { Name = "Day3-IGW" }
}

# 5. റൂട്ട് ടേബിൾ (ഇന്റർനെറ്റിലേക്കുള്ള വഴി കാണിച്ചു കൊടുക്കുന്നു)
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.day3_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 6. സബ്നെറ്റുകളെ റൂട്ട് ടേബിളുമായി ബന്ധിപ്പിക്കുന്നു
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}
# 1. സെക്യൂരിറ്റി ഗ്രൂപ്പ് (ലോഡ് ബാലൻസറിന് വേണ്ടി)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.day3_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ഇന്റർനെറ്റിൽ നിന്ന് ആർക്കും ആക്സസ് ചെയ്യാം
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id] # രണ്ട് AZ-കളിലും വർക്ക് ചെയ്യും
}

# 3. Target Group (ട്രാഫിക് എങ്ങോട്ട് വിടണം എന്ന് തീരുമാനിക്കുന്നു)
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

# 4. Listener (ലോഡ് ബാലൻസർ എന്ത് ശ്രദ്ധിക്കണം)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ഔട്ട്‌പുട്ട്: ലോഡ് ബാലൻസറിന്റെ ലിങ്ക് കാണാൻ
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
# 1. Launch Template (സെർവർ എങ്ങനെയായിരിക്കണം എന്നുള്ള പ്ലാൻ)
resource "aws_launch_template" "web_config" {
  name_prefix   = "web-server-template"
  image_id      = "ami-09040d770ffe2224f" # Ubuntu AMI (us-east-2)
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.alb_sg.id] # ALB-യുടെ അതേ SG ഉപയോഗിക്കാം
  }

  # വെബ് സെർവർ ഇൻസ്റ്റാൾ ചെയ്യാനുള്ള സ്ക്രിപ്റ്റ്
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nginx
              echo "<h1>Day 3: High Availability Server is LIVE!</h1>" > /var/www/html/index.html
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  )
}

# 2. Auto Scaling Group (സെർവറുകളുടെ എണ്ണം നിയന്ത്രിക്കുന്നു)
resource "aws_autoscaling_group" "web_asg" {
  vpc_zone_identifier = [aws_subnet.sub1.id, aws_subnet.sub2.id] # രണ്ട് AZ-കളിലും സെർവർ വരാം
  desired_capacity    = 2 # എപ്പോഴും 2 സെർവറുകൾ ഉണ്ടാകണം
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.web_config.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn] # ALB-യുമായി ബന്ധിപ്പിക്കുന്നു

  tag {
    key                 = "Name"
    value               = "ASG-Web-Server"
    propagate_at_launch = true
  }
}
