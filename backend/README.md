# Backend Application

A simple Node.js Express API containerized with Docker for deployment on AWS EC2.

## 📋 Overview

This is a basic Express.js REST API that can be deployed using Docker Compose on the provisioned EC2 instance.

## 🛠 Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Containerization**: Docker
- **Orchestration**: Docker Compose

## 🚀 Local Development

### Prerequisites
- Node.js (v14+)
- Docker and Docker Compose (optional for containerized development)

### Install Dependencies
```bash
cd backend
npm install
```

### Run Locally (Without Docker)
```bash
node index.js
```

The server will start on `http://localhost:3000`

### Run with Docker Compose
```bash
docker-compose up -d
```

The application will be available at `http://localhost:3000`

## 🐳 Docker Deployment

### Build Docker Image
```bash
docker build -t backend-app .
```

### Run Container
```bash
docker run -d -p 3000:3000 --name backend backend-app
```

### Using Docker Compose
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

## 📦 Deploying to EC2

After your EC2 instance is provisioned with Terraform and Ansible:

### 1. Copy Backend Files to Server
```bash
# From the first-class directory
scp -i newkeys -r backend ubuntu@<public_ip>:/home/ubuntu/
```

### 2. SSH to the Server
```bash
ssh -i newkeys ubuntu@<public_ip>
```

### 3. Deploy with Docker Compose
```bash
cd ~/backend
docker-compose up -d
```

### 4. Verify Deployment
```bash
# Check if container is running
docker ps

# Test the API
curl http://localhost:3000

# View logs
docker-compose logs -f
```

### 5. Access from Outside
Make sure port 3000 is allowed in the security group, or use Nginx as a reverse proxy.

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the backend directory:
```env
PORT=3000
NODE_ENV=production
```

Update `docker-compose.yml` to use it:
```yaml
services:
  web:
    env_file:
      - .env
```

### Nginx Reverse Proxy

To serve the backend through Nginx on port 80, SSH to the server and create an Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/backend
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name <your_domain_or_ip>;

    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the configuration:
```bash
sudo ln -s /etc/nginx/sites-available/backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 📡 API Endpoints

### GET /
```bash
curl http://localhost:3000/
```
Response:
```json
{
  "message": "Welcome to the API"
}
```

### Health Check
Add a health endpoint by updating `index.js`:
```javascript
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});
```

## 🐛 Troubleshooting

### Container Won't Start

**Check logs**:
```bash
docker-compose logs
```

**Inspect container**:
```bash
docker inspect backend-web-1
```

**Check if port is in use**:
```bash
sudo lsof -i :3000
```

### Permission Denied (Docker)

**Solution**: Make sure ubuntu user is in docker group (Ansible does this automatically):
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Cannot Connect to API

**Check if container is running**:
```bash
docker ps
```

**Check firewall/security group**:
```bash
# On EC2
sudo ufw status

# In AWS Console
# Verify security group allows inbound on port 3000
```

**Test from within the server**:
```bash
curl http://localhost:3000
```

## 🔄 Updates and Redeployment

To update the application:

```bash
# 1. Pull latest code or copy new files
scp -i ../newkeys -r * ubuntu@<public_ip>:/home/ubuntu/backend/

# 2. SSH to server
ssh -i ../newkeys ubuntu@<public_ip>

# 3. Rebuild and restart
cd ~/backend
docker-compose down
docker-compose up -d --build

# 4. Verify
docker-compose logs -f
```

## 🔐 Production Considerations

1. **Environment Variables**: Never commit sensitive data
2. **HTTPS**: Use Let's Encrypt with Nginx for SSL/TLS
3. **Monitoring**: Add health checks and logging
4. **Persistence**: Use volumes for data that needs to persist
5. **Resource Limits**: Set memory and CPU limits in docker-compose.yml:
   ```yaml
   services:
     web:
       deploy:
         resources:
           limits:
             cpus: '0.5'
             memory: 512M
   ```

## 📊 Monitoring

### View Real-time Logs
```bash
docker-compose logs -f --tail=100
```

### Container Stats
```bash
docker stats
```

### Disk Usage
```bash
docker system df
```

## 🧹 Cleanup

### Stop and Remove Containers
```bash
docker-compose down
```

### Remove Images
```bash
docker rmi backend-backend
```

### Clean Up All Unused Resources
```bash
docker system prune -a
```

---

**Note**: This is a basic setup for development and testing. For production, consider using:
- Container orchestration (ECS, EKS, or Kubernetes)
- Load balancers
- Auto-scaling groups
- Database services (RDS)
- Monitoring and logging solutions (CloudWatch, ELK stack)

