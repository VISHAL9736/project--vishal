# OLake Deployment on Minikube using Terraform

**Author**: Vishal  
**Cloud Provider**: AWS  
**Date**: 06 November 2025

## 📋 Table of Contents
- [Overview]
- [Prerequisites]
- [Architecture]
- [Setup Instructions]
- [Accessing OLake UI]
- [Verification]
- [Troubleshooting]
- [Cleanup Instructions]
- [Project Structure]

## 🎯 Overview

This project demonstrates Infrastructure as Code (IaC) using Terraform to:
- Provision AWS EC2 infrastructure with VPC, subnets, and security groups
- Automatically install Docker, kubectl, Helm, and Minikube
- Deploy OLake application using Helm charts
- Configure ingress and port forwarding for external access

**Specifications:**
- **VM**: t3.xlarge (4 vCPU, 16GB RAM, 50GB storage)
- **OS**: Ubuntu 24.04 LTS
- **Kubernetes**: Minikube (single-node cluster)
- **Container Runtime**: Docker
- **Package Manager**: Helm 3.x

## 🔧 Prerequisites

### Required Software
1. **Terraform** (>= 1.0)

   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform --version


2. **AWS CLI** (>= 2.0)

   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws --version


3. **SSH Key Pair**

   # Generate SSH keys
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa


### AWS Account Requirements
- Active AWS account
- IAM user with EC2, VPC, and networking permissions
- AWS credentials configured


## 🏗️ Architecture

┌─────────────────────────────────────────────────┐
│              AWS Cloud (us-east-1)              │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │           VPC (10.0.0.0/16)               │ │
│  │                                           │ │
│  │  ┌─────────────────────────────────────┐ │ │
│  │  │  Public Subnet (10.0.1.0/24)        │ │ │
│  │  │                                     │ │ │
│  │  │  ┌───────────────────────────────┐ │ │ │
│  │  │  │   EC2: t3.xlarge              │ │ │ │
│  │  │  │   Ubuntu 24.04 LTS            │ │ │ │
│  │  │  │                               │ │ │ │
│  │  │  │   ┌─────────────────────────┐ │ │ │ │
│  │  │  │   │  Minikube Cluster       │ │ │ │ │
│  │  │  │   │                         │ │ │ │ │
│  │  │  │   │  - OLake UI             │ │ │ │ │
│  │  │  │   │  - OLake Workers        │ │ │ │ │
│  │  │  │   │  - PostgreSQL           │ │ │ │ │
│  │  │  │   │  - Elasticsearch        │ │ │ │ │
│  │  │  │   │  - Temporal             │ │ │ │ │
│  │  │  │   │  - NFS Server           │ │ │ │ │
│  │  │  │   └─────────────────────────┘ │ │ │ │
│  │  │  └───────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────┘ │ │
│  │                                           │ │
│  │  Security Group:                          │ │
│  │  - Port 22 (SSH)                          │ │
│  │  - Port 8000 (OLake UI)                   │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘


## 🚀 Setup Instructions

### Step 1: Configure AWS Credentials

# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity


### Step 2: Prepare Project Files

# Clone or download the project
cd OLake_Assignment_Vishal

# Verify directory structure
ls -la


### Step 3: Configure Variables

cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars


**Update terraform.tfvars:**

aws_region   = "us-east-1"
project_name = "olake-deployment"
environment  = "dev"
owner        = "Vishal"

ami_id           = "ami-0ecb62995f68bb549"
instance_type    = "t3.xlarge"
root_volume_size = 50

# Update with your IP from whatismyipaddress.com
allowed_ssh_cidr = ["YOUR_IP/32"]

ssh_public_key_path  = "~/.ssh/id_rsa.pub"
ssh_private_key_path = "~/.ssh/id_rsa"


### Step 4: Initialize Terraform

cd terraform
terraform init


**Expected Output:**

Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
Terraform has been successfully initialized!


### Step 5: Validate Configuration

terraform validate


**Expected Output:**

Success! The configuration is valid.


### Step 6: Plan Deployment

terraform plan


Review the plan carefully. Should show ~15-20 resources to be created.

### Step 7: Apply Configuration

terraform apply


Type `yes` when prompted.

**⏱️ Deployment Time: 20-30 minutes**

**Stages:**
1. Infrastructure creation (3-5 min)
2. Dependency installation (5-7 min)
3. Minikube setup (3-5 min)
4. OLake deployment (10-15 min)

### Step 8: Save Outputs

# View all outputs
terraform output

# Save to file
terraform output > ../deployment-info.txt

# Get specific outputs
terraform output instance_public_ip
terraform output olake_ui_url


## 🌐 Accessing OLake UI

### Method 1: Direct Browser Access

1. Get the OLake UI URL:

   terraform output olake_ui_url


2. Open in browser:

   http://<INSTANCE_PUBLIC_IP>:8000


3. **Login Credentials:**
   - Username: `admin`
   - Password: `password`

### Method 2: Verify via SSH



# SSH into the instance
ssh -i ~/.ssh/id_rsa ubuntu@

# Check deployment status
cat ~/deployment-summary.txt

# Verify pods
kubectl get pods -n olake

# Check port forwarding
sudo systemctl status olake-port-forward


##  Verification

### 1. Check Infrastructure

# From local machine
terraform show | grep instance_state
# Should show: instance_state = "running"

# View all resources
terraform state list


### 2. SSH and Verify Kubernetes

# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@

# Check Minikube
minikube status

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check OLake pods
kubectl get pods -n olake


**Expected Pod Status:**

NAME                            READY   STATUS      RESTARTS   AGE
elasticsearch-0                 1/1     Running     0          10m
olake-nfs-server-0              1/1     Running     0          10m
olake-signup-init-xn25m         0/1     Completed   0          10m
olake-ui-7bdd7dc64-j7kjh        1/1     Running     0          10m
olake-workers-cc87d7d9f-rpqjr   1/1     Running     0          10m
postgresql-0                    1/1     Running     0          10m
temporal-85cb4886d6-pm8w5       1/1     Running     0          10m


### 3. Check Services

kubectl get svc -n olake


### 4. Verify Port Forwarding

# Check service status
sudo systemctl status olake-port-forward

# Check port is listening
sudo netstat -tlnp | grep 8000

# Test locally
curl http://localhost:8000


### 5. Test External Access

From your browser:

http://<INSTANCE_PUBLIC_IP>:8000


Should show OLake login page.

## 🔍 Troubleshooting

### Issue 1: Cannot SSH into Instance

**Solution:**

# Wait 2-3 minutes for cloud-init to complete

# Check security group
aws ec2 describe-security-groups --group-ids 

# Verify your IP
curl https://checkip.amazonaws.com

# Update security group if needed
terraform apply


### Issue 2: OLake UI Not Accessible

**Solution:**

# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@

# Check port forwarding
sudo systemctl status olake-port-forward

# Restart if needed
sudo systemctl restart olake-port-forward

# Verify pods are running
kubectl get pods -n olake

# Check logs
kubectl logs -n olake -l app=olake-ui


### Issue 3: Pods Not Starting

**Solution:**

# Describe pod
kubectl describe pod  -n olake

# Check events
kubectl get events -n olake --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes

# Verify storage class
kubectl get storageclass


### Issue 4: Terraform Apply Fails

**Solution:**

# Check AWS credentials
aws sts get-caller-identity

# Clean up and retry
terraform destroy
rm -rf .terraform
terraform init
terraform apply


## 🧹 Cleanup Instructions

### ⚠️ IMPORTANT: Run Immediately After Testing!

### Step 1: Destroy All Resources

cd terraform
terraform destroy


Type `yes` when prompted.

**This will remove:**
- EC2 instance
- VPC and networking
- Security groups
- SSH key pair

**⏱️ Cleanup Time: 5-10 minutes**

### Step 2: Verify Cleanup

# Check no instances remain
aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=OLake-Deployment" \
    --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
    --output table

# Should show: terminated or empty


### Step 3: Verify in AWS Console

Check these in AWS Console:
- ✅ EC2 Instances: None with your tags
- ✅ VPCs: None with project name
- ✅ Security Groups: None with project name
- ✅ Key Pairs: Removed

### Cost Estimate

**Running Cost:**
- t3.xlarge: ~$0.17/hour
- **Daily cost**: ~$4
- **Keep it minimal!**

## 📁 Project Structure

OLake_Assignment_Vishal/
├── terraform/
│   ├── main.tf                 # Main infrastructure code
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   └── terraform.tfvars        # Your actual values (NOT in ZIP)
├── scripts/
│   ├── install-dependencies.sh # Install Docker, kubectl, Helm, Minikube
│   ├── start-minikube.sh       # Start Minikube with addons
│   └── deploy-olake.sh         # Deploy OLake via Helm
├── values.yaml                 # Custom Helm values for OLake
├── screenshots/
│   ├── 01-terraform-apply.png
│   ├── 02-olake-login.png
│   ├── 03-olake-dashboard.png
│   ├── 04-kubectl-pods.png
│   └── 05-terraform-destroy.png
└── README.md                   # This file


##  Resource Specifications

| Component | Specification | Notes |
|-----------|--------------|-------|
| **Cloud Provider** | AWS | us-east-1 region |
| **VM Type** | t3.xlarge | 4 vCPU, 16GB RAM |
| **Storage** | 50GB | GP3 SSD, encrypted |
| **OS** | Ubuntu 24.04 LTS | AMI: ami-0ecb62995f68bb549 |
| **Kubernetes** | Minikube | Single-node cluster |
| **Container Runtime** | Docker | Latest stable version |
| **Helm** | Version 3.x | Latest stable |
| **OLake** | v0.0.5 | From official Helm repo |

## 🔒 Security Considerations

- SSH access restricted via security group
- Only ports 22 and 8000 exposed
- Root volume encrypted
- IMDSv2 enforced
- No hardcoded credentials
- All secrets in .gitignore

## 🎓 Key Learning Points

This project demonstrates:
- ✅ Infrastructure as Code with Terraform
- ✅ Cloud resource provisioning (VPC, EC2, Security Groups)
- ✅ Automated deployment using provisioners
- ✅ Kubernetes cluster management with Minikube
- ✅ Helm package management
- ✅ Service exposure and networking
- ✅ DevOps best practices

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [OLake Documentation](https://olake.io/docs)

##  Support

For issues or questions:
1. Check Troubleshooting section
2. Review logs: `/var/log/user-data.log` on VM
3. Check Terraform state: `terraform show`
4. Verify AWS Console

---

**Project completed as part of DevOps Intern Assignment for DataZip**

**Contact**: vishalkhan8786@gmail.com  

**Date**: 06 November 2025
 ## Thanks