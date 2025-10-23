terraform {
  backend "s3" {
    bucket = "terraform-first-class"
    region = "us-east-2"
    key = "first-class/terraform.tfstate"
    profile = "terraform"
  }
}

provider "aws" {
  region = "us-east-2"
  profile = "terraform"
}