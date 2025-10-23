

# Web Instance
resource "aws_instance" "web" {
 ami =  data.aws_ami.ubuntu.id
 instance_type = var.instance_type.web
 subnet_id = module.vpc.public_subnets[0]
 vpc_security_group_ids = [aws_security_group.web_security_group.id]
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

# Jenkins Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type.jenkins
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.mykey.key_name
  
  tags = {
    Name = "jenkins-server"
  }

  provisioner "local-exec" {
    command = "printf '[jenkins_servers]\\n%s ansible_user=ubuntu ansible_ssh_private_key_file=%s\\n' '${self.public_ip}' '${abspath(path.module)}/newkeys' > ${path.module}/jenkins-inventory.ini"
  }

  provisioner "local-exec" {
    command = "sleep 30 && ANSIBLE_CONFIG=${path.module}/templates/ansible.cfg ansible-playbook -i ${path.module}/jenkins-inventory.ini ${path.module}/templates/jenkins-playbook.yml"
  }
}