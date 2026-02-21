variable "aws_region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  # Ubuntu 24.04 AMI (us-east-2 region)
  default = "ami-09040d770ffe2224f" 
}