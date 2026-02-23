terraform {
  backend "s3" {
    bucket         = "alaison-terraform-state-2026"
    key            = "day3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}