# Quick Start Guide

Fast reference for common operations and commands.

## 🚀 Initial Setup

```bash
# 1. Generate SSH keys (if needed)
ssh-keygen -t rsa -b 4096 -f newkeys -N ""

# 2. Initialize Terraform
terraform init

# 3. Deploy infrastructure
terraform apply

# 4. Get public IP
terraform output public_ip
```

## 🔑 SSH Access

```bash
# Connect to instance
ssh -i newkeys ubuntu@$(terraform output -raw public_ip)

# Copy files to instance
scp -i newkeys -r backend ubuntu@$(terraform output -raw public_ip):/home/ubuntu/

# Execute remote command
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "docker ps"
```

## 🎭 Ansible Commands

```bash
# Test connection
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m ping -i inventory.ini

# Run playbook
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml

# Run with verbose output
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml -vvv

# Dry run (check mode)
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml --check

# Run specific command on all hosts
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m shell -a "systemctl status nginx" -i inventory.ini

# Check Docker status
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m shell -a "docker --version" -i inventory.ini
```

## 🔧 Terraform Operations

```bash
# Preview changes
terraform plan

# Apply changes
terraform apply

# Apply without confirmation
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Refresh state
terraform refresh

# Force recreate instance
terraform taint aws_instance.web
terraform apply

# Format code
terraform fmt

# Validate configuration
terraform validate

# View outputs
terraform output
terraform output public_ip
terraform output -raw public_ip  # without quotes
```

## 🐳 Docker Commands (On Server)

```bash
# SSH to server first
ssh -i newkeys ubuntu@$(terraform output -raw public_ip)

# Check Docker version
docker --version

# List running containers
docker ps

# List all containers
docker ps -a

# View logs
docker logs <container_id>

# Stop container
docker stop <container_id>

# Remove container
docker rm <container_id>

# List images
docker images

# Remove image
docker rmi <image_id>

# Build image
docker build -t myapp .

# Run container
docker run -d -p 3000:3000 myapp

# Container stats
docker stats

# Clean up
docker system prune -a
```

## 🐳 Docker Compose (On Server)

```bash
# Navigate to backend directory
cd ~/backend

# Start services
docker-compose up -d

# View logs
docker-compose logs
docker-compose logs -f  # follow logs

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# View running services
docker-compose ps

# Execute command in service
docker-compose exec web sh

# Scale service
docker-compose up -d --scale web=3
```

## 🌐 Nginx Commands (On Server)

```bash
# Check Nginx status
sudo systemctl status nginx

# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Restart Nginx
sudo systemctl restart nginx

# Reload configuration
sudo systemctl reload nginx

# Test configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log

# View access logs
sudo tail -f /var/log/nginx/access.log

# Edit default site config
sudo nano /etc/nginx/sites-available/default
```

## 🔍 Debugging

```bash
# Check if port is listening
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :3000

# Check process
ps aux | grep nginx
ps aux | grep docker

# Check disk usage
df -h

# Check memory
free -h

# Check system logs
sudo journalctl -u nginx -f
sudo journalctl -u docker -f

# Test HTTP endpoint
curl http://localhost
curl http://localhost:3000

# Check security group (locally)
aws ec2 describe-security-groups --group-ids $(terraform output -json | jq -r '.security_group_id.value') --profile terraform

# Check instance status (locally)
aws ec2 describe-instance-status --instance-ids $(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_instance.web") | .values.id') --profile terraform
```

## 📊 Monitoring

```bash
# System resources
htop
top

# Disk usage
du -sh *
ncdu

# Network connections
sudo netstat -an | grep ESTABLISHED

# Docker resource usage
docker stats --no-stream

# Check open files
lsof -i :80
lsof -i :3000

# Process tree
pstree -p
```

## 🧹 Cleanup

```bash
# On server - stop all containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

# On server - remove all images
docker rmi $(docker images -q)

# On server - complete Docker cleanup
docker system prune -a --volumes -f

# Locally - destroy infrastructure
terraform destroy -auto-approve

# Locally - clean Terraform files
rm -rf .terraform terraform.tfstate* .terraform.lock.hcl
```

## 🔄 Update Workflow

```bash
# 1. Make changes to code
# 2. Copy to server
scp -i newkeys -r backend ubuntu@$(terraform output -raw public_ip):/home/ubuntu/

# 3. SSH to server
ssh -i newkeys ubuntu@$(terraform output -raw public_ip)

# 4. Rebuild and restart
cd ~/backend
docker-compose down
docker-compose up -d --build

# 5. Verify
docker-compose logs -f
curl http://localhost:3000
```

## 🆘 Emergency Commands

```bash
# Kill all Docker containers
docker kill $(docker ps -q)

# Force remove container
docker rm -f <container_id>

# Restart Docker service
sudo systemctl restart docker

# Restart server
sudo reboot

# Force Terraform state unlock (if locked)
terraform force-unlock <lock_id>

# Emergency destroy with no backup
terraform destroy -backup=- -auto-approve
```

## 📋 Useful One-Liners

```bash
# Get public IP
terraform output -raw public_ip

# Quick SSH
ssh -i newkeys ubuntu@$(terraform output -raw public_ip)

# Test web server
curl http://$(terraform output -raw public_ip)

# Watch logs
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "docker-compose -f /home/ubuntu/backend/docker-compose.yml logs -f"

# Container status from local machine
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "docker ps"

# Check Nginx from local machine
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "sudo systemctl status nginx"

# Deploy and check in one command
terraform apply -auto-approve && sleep 5 && curl http://$(terraform output -raw public_ip)
```

## 🔐 Security Checks

```bash
# Check SSH key permissions
ls -la newkeys  # should be 400 or 600

# Fix SSH key permissions
chmod 400 newkeys

# Check security group rules
terraform state show aws_security_group.allow_ssh

# Verify firewall on server
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "sudo ufw status"

# Check for updates on server
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) "sudo apt update && sudo apt list --upgradable"
```

## 📱 Quick Health Checks

```bash
# Full system check script
ssh -i newkeys ubuntu@$(terraform output -raw public_ip) << 'EOF'
echo "=== System Info ==="
uname -a
echo ""
echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager
echo ""
echo "=== Docker Status ==="
sudo systemctl status docker --no-pager
echo ""
echo "=== Running Containers ==="
docker ps
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Memory Usage ==="
free -h
EOF
```

## 🎯 Common Issues & Fixes

| Issue | Quick Fix |
|-------|-----------|
| Ansible can't connect | Increase sleep time in `instance.tf` line 28 |
| Permission denied (docker) | Run `newgrp docker` or logout/login |
| Port 80 not accessible | Check security group and Nginx status |
| Container won't start | Check logs: `docker-compose logs` |
| Out of disk space | Run `docker system prune -a` |
| Terraform state locked | Run `terraform force-unlock <ID>` |
| Can't SSH to instance | Check key permissions: `chmod 400 newkeys` |
| Nginx not running | `sudo systemctl start nginx` |

---

## 💡 Tips

- Use `terraform output -raw public_ip` for scripting (no quotes)
- Add `-auto-approve` to `terraform apply` for automation
- Use `-vvv` flag with Ansible for debugging
- Always test with `curl` before checking in browser
- Keep `newkeys` file secure (400 permissions)
- Use `docker-compose logs -f` to watch real-time logs
- Run `terraform fmt` before committing

## 📚 Documentation Files

- `README.md` - Main project documentation
- `backend/README.md` - Backend application guide
- `templates/ANSIBLE.md` - Ansible playbook details
- `QUICKSTART.md` - This file

---

**Pro Tip**: Save this file to your bookmarks or create aliases for frequently used commands!

