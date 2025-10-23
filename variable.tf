variable "instance_type" {
    type = map
    default = {
        "web" = "t3.micro",
        "jenkins" = "t3.small",
        "other_instance" = "t2.micro"
    }
}

variable "aws_region" {
  default = "us-east-2"
}