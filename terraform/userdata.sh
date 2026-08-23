#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Create app directory
mkdir -p /opt/${project_name}
chown ec2-user:ec2-user /opt/${project_name}

echo "Docker and Docker Compose installed successfully" > /var/log/userdata.log
