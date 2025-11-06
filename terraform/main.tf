terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "OLake-Deployment"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      Purpose     = "DevOps-Assignment"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "olake_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "olake_igw" {
  vpc_id = aws_vpc.olake_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "olake_public_subnet" {
  vpc_id                  = aws_vpc.olake_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "olake_public_rt" {
  vpc_id = aws_vpc.olake_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.olake_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "olake_public_rta" {
  subnet_id      = aws_subnet.olake_public_subnet.id
  route_table_id = aws_route_table.olake_public_rt.id
}

# Security Group
resource "aws_security_group" "olake_sg" {
  name        = "${var.project_name}-security-group"
  description = "Security group for OLake deployment VM"
  vpc_id      = aws_vpc.olake_vpc.id

  # SSH access (Port 22)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # OLake UI access (Port 8000)
  ingress {
    description = "OLake UI access"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API (Port 8443)
  ingress {
    description = "Kubernetes API"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# Create SSH Key Pair
resource "aws_key_pair" "olake_key" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name = "${var.project_name}-key"
  }
}

# EC2 Instance
resource "aws_instance" "olake_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  subnet_id                   = aws_subnet.olake_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.olake_sg.id]
  key_name                    = aws_key_pair.olake_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data = file("${path.module}/../scripts/install-dependencies.sh")

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-vm"
    Role = "OLake-Host"
  }
}

# Wait for instance to be ready
resource "null_resource" "wait_for_dependencies" {
  depends_on = [aws_instance.olake_vm]

  provisioner "remote-exec" {
    inline = [ 
      "sleep 30",
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Waiting for dependency installation...'",
      "while [ ! -f /var/log/user-data-complete ]; do sleep 5; done",
      "echo 'Dependencies installed successfully!'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "25m"
    }
  }
}

# Start Minikube
resource "null_resource" "start_minikube" {
  depends_on = [null_resource.wait_for_dependencies]

  provisioner "file" {
    source      = "${path.module}/../scripts/start-minikube.sh"
    destination = "/tmp/start-minikube.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/start-minikube.sh",
      "/tmp/start-minikube.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "15m"
    }
  }
}

# Deploy OLake
resource "null_resource" "deploy_olake" {
  depends_on = [null_resource.start_minikube]

  provisioner "file" {
    source      = "${path.module}/../values.yaml"
    destination = "/home/ubuntu/values.yaml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "5m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/../scripts/deploy-olake.sh"
    destination = "/tmp/deploy-olake.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy-olake.sh",
      "/tmp/deploy-olake.sh ${aws_instance.olake_vm.public_ip}"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/vishal/.ssh/id_rsa")
      host        = aws_instance.olake_vm.public_ip
      timeout     = "15m"
    }
  }
}