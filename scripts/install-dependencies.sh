#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting Dependency Installation ==="
echo "Timestamp: $(date)"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

echo "=== Installing required packages ==="
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    wget \
    vim \
    htop \
    net-tools \
    conntrack \
    socat

echo "=== Installing Docker ==="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
docker --version

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

echo "=== Installing Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
minikube version

mkdir -p /home/ubuntu/.kube
chown -R ubuntu:ubuntu /home/ubuntu/.kube

mkdir -p /home/ubuntu/.minikube
chown -R ubuntu:ubuntu /home/ubuntu/.minikube

touch /var/log/user-data-complete

echo "=== Dependency installation completed ==="
echo "Timestamp: $(date)"