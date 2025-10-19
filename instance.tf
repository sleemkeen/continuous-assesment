provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
 ami =  data.aws_ami.ubuntu.id
 instance_type = var.instance_type.web
 subnet_id = module.vpc.public_subnets[0]
 vpc_security_group_ids = [aws_security_group.allow_ssh.id]
 key_name = aws_key_pair.mykey.key_name
 
 tags = {
    Name = "free-tier-instance"
 }
 provisioner "local-exec" {
   command = "printf '[web_servers]\\n%s ansible_user=ubuntu ansible_ssh_private_key_file=%s\\n' '${self.public_ip}' '${abspath(path.module)}/newkeys' > ${path.module}/inventory.ini"
 }
 provisioner "local-exec" {
   command = "sleep 30 && ANSIBLE_CONFIG=${path.module}/templates/ansible.cfg ansible-playbook -i ${path.module}/inventory.ini ${path.module}/templates/playbook.yml"
 }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_key_pair" "mykey" {
  key_name   = "mykey-demo"
  public_key = file("${path.module}/newkeys.pub")
}