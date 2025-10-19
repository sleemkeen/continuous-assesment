# Ansible Provisioning Documentation

This document explains the Ansible automation used to configure EC2 instances with Nginx and Docker.

## 📋 Overview

The Ansible playbook (`playbook.yml`) automates the installation and configuration of:
- Nginx web server
- Docker Engine and Docker Compose
- Required system dependencies

## 📁 Files

### `playbook.yml`
Main playbook that defines all provisioning tasks

### `ansible.cfg`
Configuration file that sets Ansible behavior:
- Disables host key checking for automation
- Sets SSH connection parameters
- Configures timeouts and performance settings

## 🎯 Playbook Structure

### Host Configuration
```yaml
hosts: web_servers
become: yes
gather_facts: yes
```
- **hosts**: Targets the `web_servers` group from inventory
- **become**: Runs tasks with sudo privileges
- **gather_facts**: Collects system information for use in tasks

## 📝 Task Breakdown

### 1. Connection Verification
```yaml
- name: Wait for SSH to be available
  wait_for_connection:
    delay: 5
    timeout: 300
```
**Purpose**: Ensures SSH connection is ready before proceeding
- Waits 5 seconds before first check
- Timeout after 300 seconds (5 minutes)
- Critical for newly launched instances

### 2. System Update
```yaml
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
```
**Purpose**: Updates package lists
- Only updates if cache is older than 1 hour (3600 seconds)
- Prevents unnecessary updates on multiple runs

### 3. Install Base Dependencies
```yaml
- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - software-properties-common
    state: present
```
**Purpose**: Installs packages needed for adding Docker repository
- **apt-transport-https**: Allows apt to retrieve packages over HTTPS
- **ca-certificates**: SSL/TLS certificate validation
- **curl**: Data transfer tool
- **gnupg**: Encryption and signing tool
- **lsb-release**: Linux Standard Base version info
- **software-properties-common**: Manages software repositories

### 4. Nginx Installation
```yaml
- name: Install Nginx
  apt:
    name: nginx
    state: present

- name: Start and enable Nginx
  systemd:
    name: nginx
    state: started
    enabled: yes
```
**Purpose**: Installs and configures Nginx web server
- Installs latest stable version from Ubuntu repos
- Starts service immediately
- Enables service to start on boot

### 5. Docker Repository Setup
```yaml
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
```
**Purpose**: Adds official Docker repository
- Verifies packages with GPG key
- Uses detected Ubuntu release (focal, jammy, etc.)
- Installs from official Docker repos (not Ubuntu's older versions)

### 6. Docker Installation
```yaml
- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
    state: present
```
**Purpose**: Installs complete Docker setup
- **docker-ce**: Docker Community Edition engine
- **docker-ce-cli**: Docker command-line interface
- **containerd.io**: Container runtime
- **docker-compose-plugin**: Docker Compose v2 plugin

### 7. Docker Service Configuration
```yaml
- name: Start and enable Docker
  systemd:
    name: docker
    state: started
    enabled: yes

- name: Add ubuntu user to docker group
  user:
    name: ubuntu
    groups: docker
    append: yes
```
**Purpose**: Configures Docker service and user permissions
- Starts Docker daemon
- Enables Docker to start on boot
- Allows ubuntu user to run Docker without sudo
- **Note**: User must log out/in for group changes to take effect

### 8. Verification
```yaml
- name: Verify Nginx installation
  command: nginx -v
  register: nginx_version
  changed_when: false

- name: Verify Docker installation
  command: docker --version
  register: docker_version
  changed_when: false

- name: Display versions
  debug:
    msg:
      - "Nginx version: {{ nginx_version.stderr }}"
      - "Docker version: {{ docker_version.stdout }}"
```
**Purpose**: Confirms successful installation
- Captures version information
- `changed_when: false` prevents marking as changed state
- Displays versions in Ansible output for verification

## 🚀 Running the Playbook

### Automatic Execution (via Terraform)
The playbook runs automatically when Terraform creates the instance:
```bash
terraform apply
```

### Manual Execution
Run independently of Terraform:
```bash
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml
```

### Dry Run (Check Mode)
Test without making changes:
```bash
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml --check
```

### Run Specific Tasks
Using tags (requires adding tags to playbook):
```bash
# Example with tags
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml --tags "nginx"
```

### Verbose Output
For debugging:
```bash
ANSIBLE_CONFIG=templates/ansible.cfg ansible-playbook -i inventory.ini templates/playbook.yml -vvv
```

## 📊 Inventory File

The `inventory.ini` file is auto-generated by Terraform:

```ini
[web_servers]
x.x.x.x ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/newkeys
```

**Components**:
- `[web_servers]`: Group name referenced in playbook
- `x.x.x.x`: Public IP of EC2 instance
- `ansible_user=ubuntu`: SSH username
- `ansible_ssh_private_key_file`: Path to SSH private key

## ⚙️ Ansible Configuration

The `ansible.cfg` file contains:

```ini
[defaults]
host_key_checking = False       # Skip SSH host key verification
timeout = 30                    # SSH connection timeout
deprecation_warnings = False    # Hide deprecation messages
retry_files_enabled = False     # Don't create .retry files

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
pipelining = True              # Improves performance
```

### Why Disable Host Key Checking?
- **Automation**: Allows unattended execution
- **Dynamic IPs**: EC2 instances get new IPs on recreation
- **CI/CD**: Required for automated pipelines

⚠️ **Security Note**: Only use this for automated provisioning of new instances. For production management, enable host key checking.

## 🔧 Customization

### Add More Packages
Add to the package list:
```yaml
- name: Install additional packages
  apt:
    name:
      - git
      - vim
      - htop
      - python3-pip
    state: present
```

### Configure Nginx
Add a configuration task:
```yaml
- name: Configure Nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/default
  notify: Reload Nginx

handlers:
  - name: Reload Nginx
    systemd:
      name: nginx
      state: reloaded
```

### Install Node.js
Add Node.js installation:
```yaml
- name: Add NodeSource repository
  shell: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  args:
    warn: false

- name: Install Node.js
  apt:
    name: nodejs
    state: present
```

### Set Up Firewall
Add UFW configuration:
```yaml
- name: Install UFW
  apt:
    name: ufw
    state: present

- name: Allow SSH
  ufw:
    rule: allow
    port: '22'
    proto: tcp

- name: Allow HTTP
  ufw:
    rule: allow
    port: '80'
    proto: tcp

- name: Enable UFW
  ufw:
    state: enabled
```

## 🐛 Troubleshooting

### Connection Issues

**Problem**: `UNREACHABLE! => {"msg": "Failed to connect"}`

**Solutions**:
1. Verify instance is running: `terraform state show aws_instance.web`
2. Check SSH key permissions: `ls -la newkeys` (should be 400 or 600)
3. Verify security group allows SSH from your IP
4. Increase wait time in playbook (delay parameter)

### Package Installation Failures

**Problem**: `E: Could not get lock /var/lib/apt/lists/lock`

**Solutions**:
1. Another process might be using apt (cloud-init, unattended-upgrades)
2. Add a wait task before apt operations:
```yaml
- name: Wait for apt lock
  shell: while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done
```

### Docker Permission Denied

**Problem**: User can't run Docker commands after provisioning

**Solution**: User needs to log out and back in, or run:
```bash
newgrp docker
```

The ansible task adds the user to the group, but the change only takes effect in a new session.

### Slow Playbook Execution

**Problem**: Playbook takes very long to complete

**Solutions**:
1. Enable pipelining in `ansible.cfg` (already configured)
2. Use `async` for long-running tasks:
```yaml
- name: Install packages
  apt:
    name: package-list
  async: 300
  poll: 10
```
3. Skip gather_facts if not needed: `gather_facts: no`

## 📈 Best Practices

### 1. Idempotency
All tasks are idempotent - safe to run multiple times:
- Using `state: present` instead of install commands
- `changed_when: false` for verification tasks
- Conditional task execution

### 2. Error Handling
Add error handling:
```yaml
- name: Task that might fail
  apt:
    name: package
  register: result
  ignore_errors: yes

- name: Handle failure
  debug:
    msg: "Package installation failed"
  when: result is failed
```

### 3. Variables
Use variables for flexibility:
```yaml
vars:
  docker_packages:
    - docker-ce
    - docker-ce-cli
    - containerd.io

tasks:
  - name: Install Docker
    apt:
      name: "{{ docker_packages }}"
```

### 4. Roles
For larger projects, organize into roles:
```
roles/
├── nginx/
│   └── tasks/
│       └── main.yml
└── docker/
    └── tasks/
        └── main.yml
```

### 5. Vault for Secrets
Use Ansible Vault for sensitive data:
```bash
ansible-vault create secrets.yml
ansible-playbook playbook.yml --ask-vault-pass
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 🎯 Next Steps

1. **Add monitoring**: Install and configure monitoring tools (Prometheus, Grafana)
2. **Set up CI/CD**: Integrate with Jenkins or GitHub Actions
3. **Implement logging**: Configure centralized logging (ELK stack)
4. **Harden security**: Apply security best practices (fail2ban, UFW)
5. **Create roles**: Refactor into reusable Ansible roles
6. **Add tests**: Use Molecule for Ansible playbook testing

---

**Note**: This playbook is designed for Ubuntu 20.04 LTS. For other distributions, adjust package managers and package names accordingly.

