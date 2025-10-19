output "public_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP of the web server"
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ansible_status" {
  value = "Ansible playbook will be executed automatically after instance creation"
  description = "Status message for Ansible integration"
}