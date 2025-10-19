# Terraform + Ansible AWS Infrastructure

This project automates the deployment of an Ubuntu EC2 instance on AWS with Nginx and Docker pre-installed using Terraform and Ansible.

## 📋 Overview

This infrastructure-as-code setup:
- Creates an AWS EC2 instance (Ubuntu 20.04 LTS)
- Configures VPC with public subnets
- Sets up security groups for SSH and HTTP access
- Automatically provisions the instance with Nginx and Docker using Ansible
- Generates dynamic inventory for Ansible

## 🛠 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) (v2.9+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- SSH key pair (generated automatically or provide your own)

### AWS Requirements
- AWS account with appropriate permissions
- AWS CLI profile named `terraform` configured in `~/.aws/credentials`
- Sufficient permissions to create EC2, VPC, and Security Group resources

## 📁 Project Structure

```
first-class/
├── instance.tf              # EC2 instance and security group configuration
├── vpc.tf                   # VPC module configuration
├── variable.tf              # Variable definitions
├── output.tf                # Output values
├── inventory.ini            # Auto-generated Ansible inventory
├── newkeys                  # SSH private key (git-ignored)
├── newkeys.pub              # SSH public key
├── templates/
│   ├── playbook.yml        # Ansible playbook for provisioning
│   └── ansible.cfg         # Ansible configuration
└── backend/
    ├── docker-compose.yml  # Docker compose for backend services
    ├── Dockerfile          # Backend application Dockerfile
    ├── index.js            # Node.js backend application
    └── package.json        # Node.js dependencies
```

## 🚀 Quick Start

### 1. Initialize Terraform
```bash
cd first-class
terraform init
```

### 2. Generate SSH Key Pair (if not exists)
```bash
ssh-keygen -t rsa -b 4096 -f newkeys -N ""
```

### 3. Review and Apply Infrastructure
```bash
# Preview changes
terraform plan

# Apply changes
terraform apply
```

The provisioning process will:
1. Create VPC and networking components
2. Launch EC2 instance
3. Generate Ansible inventory automatically
4. Wait 30 seconds for instance to be ready
5. Run Ansible playbook to install software

### 4. Access Your Instance
```bash
# Get the public IP
terraform output public_ip

# SSH into the instance
ssh -i newkeys ubuntu@<public_ip>
```

## 📦 What Gets Installed

The Ansible playbook (`templates/playbook.yml`) installs and configures:

### Nginx Web Server
- Latest stable version from Ubuntu repositories
- Automatically started and enabled on boot
- Accessible on port 80

### Docker Engine
- Docker CE (Community Edition)
- Docker CLI
- Containerd runtime
- Docker Compose plugin
- Ubuntu user added to docker group for non-root access

### System Packages
- apt-transport-https
- ca-certificates
- curl
- gnupg
- lsb-release
- software-properties-common

## 🔧 Configuration

### Ansible Configuration
The `templates/ansible.cfg` file disables host key checking for automated provisioning:
- `host_key_checking = False` - Skips SSH host key verification
- `ssh_args` - Additional SSH options for automation
- `pipelining = True` - Improves performance

### Security Groups
The setup creates a security group allowing:
- **SSH (22)** - From anywhere (0.0.0.0/0)
- **HTTP (80)** - From anywhere (0.0.0.0/0)
- **All Outbound** - Full egress access

⚠️ **Security Note**: Consider restricting SSH access to specific IP ranges in production.

## 🔄 Running Ansible Manually

If you need to re-run the Ansible playbook without recreating the instance:

```bash
cd first-class
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml
```

### Verify Ansible Connection
```bash
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m ping -i inventory.ini
```

### Run Specific Tasks
```bash
# Check if Nginx is running
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m shell -a "systemctl status nginx" -i inventory.ini

# Check Docker version
ANSIBLE_CONFIG=templates/ansible.cfg ansible web_servers -m shell -a "docker --version" -i inventory.ini
```

## 🐛 Troubleshooting

### Ansible Playbook Fails During Terraform Apply

**Problem**: Ansible can't connect to the instance
```
TASK [Wait for SSH to be available] *****
fatal: [x.x.x.x]: UNREACHABLE!
```

**Solutions**:
1. **Increase sleep time**: The instance might need more time to boot
   ```hcl
   # In instance.tf, line 28
   command = "sleep 60 && ANSIBLE_CONFIG=..."
   ```

2. **Run Ansible manually** after Terraform completes:
   ```bash
   ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml
   ```

3. **Check SSH key permissions**:
   ```bash
   chmod 400 newkeys
   ```

### SSH Connection Refused

**Problem**: Can't SSH to the instance
```
ssh: connect to host x.x.x.x port 22: Connection refused
```

**Solutions**:
1. Wait a few minutes for the instance to fully boot
2. Check security group allows your IP:
   ```bash
   terraform state show aws_security_group.allow_ssh
   ```
3. Verify instance is running:
   ```bash
   aws ec2 describe-instances --profile terraform
   ```

### Terraform State Issues

**Problem**: State file conflicts or corruption

**Solutions**:
1. **Refresh state**:
   ```bash
   terraform refresh
   ```

2. **Import existing resources**:
   ```bash
   terraform import aws_instance.web <instance-id>
   ```

3. **Force recreation**:
   ```bash
   terraform taint aws_instance.web
   terraform apply
   ```

### Ansible Host Key Checking

**Problem**: SSH host key verification fails

**Solution**: The `ansible.cfg` file should handle this, but you can also:
```bash
export ANSIBLE_HOST_KEY_CHECKING=False
```

## 🔐 Security Best Practices

1. **SSH Keys**: Keep `newkeys` private and never commit to version control
2. **AWS Credentials**: Use IAM roles instead of hardcoded credentials
3. **Security Groups**: Restrict SSH access to known IP addresses
4. **State Files**: Store Terraform state remotely (S3 + DynamoDB)
5. **Secrets Management**: Use AWS Secrets Manager or Parameter Store for sensitive data

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
terraform destroy
```

This will remove:
- EC2 instance
- Security groups
- VPC and networking components
- SSH key pair from AWS (local files remain)

## 📝 Customization

### Change Instance Type
Edit `variable.tf`:
```hcl
variable "instance_type" {
  default = {
    web = "t2.micro"  # Change to t2.small, t3.medium, etc.
  }
}
```

### Modify Installed Software
Edit `templates/playbook.yml` to add or remove packages and configurations.

### Add More Security Rules
Edit `instance.tf` to add ingress rules:
```hcl
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

## 📊 Outputs

After successful deployment, Terraform outputs:
- `public_ip` - Public IP address of the EC2 instance
- `public_subnets` - List of public subnet IDs
- `vpc_id` - VPC identifier
- `ansible_status` - Confirmation message

View outputs:
```bash
terraform output
```

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements.

## 📄 License

This project is provided as-is for educational and development purposes.

---

**Note**: This setup uses AWS Free Tier eligible resources (t2.micro), but always monitor your AWS usage to avoid unexpected charges.

