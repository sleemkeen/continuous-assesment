output "web_public_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP of the web server"
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
  description = "Public IP of the Jenkins server"
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
  description = "Jenkins Web UI URL"
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ansible_status" {
  value = "Ansible playbooks will be executed automatically after instance creation"
  description = "Status message for Ansible integration"
}

output "jenkins_initial_password_location" {
  value = "SSH to Jenkins server and check /home/ubuntu/jenkins_initial_password.txt"
  description = "Location of Jenkins initial admin password"
}