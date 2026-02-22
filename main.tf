provider "aws" {
  region = var.aws_region
}

# 1. VPC നിർമ്മിക്കുന്നു
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Dev-VPC"
  }
}

# 2. സബ്നെറ്റ് (Subnet)
resource "aws_subnet" "dev_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Dev-Subnet"
  }
}

# 3. ഇന്റർനെറ്റ് ഗേറ്റ്‌വേ (സെർവറിന് ഇന്റർനെറ്റ് കിട്ടാൻ)
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
}

# 4. EC2 ഇൻസ്റ്റൻസ് (നമ്മുടെ സെർവർ)
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.dev_subnet.id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]

  tags = {
    Name = "DevOps-Server"
  }
}
# 5. സെക്യൂരിറ്റി ഗ്രൂപ്പ് (ഫയർവാൾ)
resource "aws_security_group" "dev_sg" {
  vpc_id = aws_vpc.dev_vpc.id

  # SSH ആക്സസ്
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP ആക്സസ്
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
# 1. റൂട്ട് ടേബിൾ (Route Table) നിർമ്മിക്കുന്നു
resource "aws_route_table" "dev_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "Dev-Route-Table"
  }
}

# 2. റൂട്ട് ടേബിളിനെ സബ്നെറ്റുമായി ബന്ധിപ്പിക്കുന്നു (Association)
resource "aws_route_table_association" "dev_rta" {
  subnet_id      = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.dev_rt.id
}
# 3. create s3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "alaison-terraform-state-bucket" # ഈ പേര് യൂണീക്ക് ആയിരിക്കണം
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
terraform {
  backend "s3" {
    bucket         = "alaison-terraform-state-bucket" # മുകളിൽ നൽകിയ അതേ പേര്
    key            = "dev/terraform.tfstate"
    region         = "us-east-2" # നിങ്ങളുടെ റീജിയൻ
    encrypt        = true
  }
}
