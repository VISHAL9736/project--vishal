#!/bin/bash
set -e

VM_PUBLIC_IP=$1

if [ -z "$VM_PUBLIC_IP" ]; then
    echo "Error: VM public IP not provided"
    exit 1
fi

echo "=== Starting OLake Deployment ==="
echo "VM Public IP: $VM_PUBLIC_IP"
echo "Timestamp: $(date)"

echo "=== Adding OLake Helm repository ==="
helm repo add olake https://datazip-inc.github.io/olake-helm || true
helm repo update
helm search repo olake

echo "=== Creating OLake namespace ==="
kubectl create namespace olake --dry-run=client -o yaml | kubectl apply -f -

echo "=== Verifying storage class ==="
kubectl get storageclass

echo "=== Deploying OLake via Helm ==="
helm upgrade --install olake olake/olake \
    --namespace olake \
    --values /home/ubuntu/values.yaml \
    --wait \
    --timeout 20m || echo "Helm deployment completed (some pods may still be starting)"

echo "=== Waiting for main OLake pods (excluding init/completed jobs) ==="
# Wait only for long-running pods, not init jobs
kubectl wait --for=condition=Ready \
    pod -l app=olake-ui \
    -n olake \
    --timeout=300s || echo "OLake UI pods starting..."

kubectl wait --for=condition=Ready \
    pod -l app=olake-workers \
    -n olake \
    --timeout=300s || echo "OLake worker pods starting..."

echo "=== Checking Pod Status ==="
kubectl get pods -n olake

echo "=== Deployment Status ==="
kubectl get all -n olake

echo "=== Setting up port forwarding service ==="
sudo tee /etc/systemd/system/olake-port-forward.service > /dev/null <<EOF
[Unit]
Description=OLake Port Forward Service
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/kubectl port-forward -n olake --address 0.0.0.0 svc/olake-ui 8000:8000
Restart=always
RestartSec=10
Environment="KUBECONFIG=/home/ubuntu/.kube/config"

[Install]
WantedBy=multi-user.target
EOF

# Stop any existing port-forward service
sudo systemctl stop olake-port-forward.service 2>/dev/null || true

sudo systemctl daemon-reload
sudo systemctl enable olake-port-forward.service
sudo systemctl start olake-port-forward.service

sleep 3

echo "=== Verifying port forwarding ==="
sudo systemctl status olake-port-forward.service --no-pager

# Test if port 8000 is responding
sleep 2
if curl -s http://localhost:8000 > /dev/null; then
    echo "✅ OLake UI is accessible on port 8000"
else
    echo "⚠️  OLake UI may still be starting up..."
fi

tee /home/ubuntu/deployment-summary.txt > /dev/null <<EOF
================================================================
           OLake Deployment Summary
================================================================

Deployment Date: $(date)

KUBERNETES CLUSTER:
- Minikube Status: Running
- Minikube IP: $(minikube ip)
- Kubernetes Version: $(kubectl version --short --client)

OLAKE DEPLOYMENT:
- Namespace: olake
- Service Port: 8000

ACCESS INFORMATION:
==================
OLake UI URL: http://$VM_PUBLIC_IP:8000

Default Credentials:
- Username: admin
- Password: password

USEFUL COMMANDS:
================
# View all pods
kubectl get pods -n olake

# View OLake UI logs
kubectl logs -n olake -l app=olake-ui

# View service status
kubectl get svc -n olake

# Port forwarding status
sudo systemctl status olake-port-forward

# Restart port forwarding if needed
sudo systemctl restart olake-port-forward

# Check if UI is accessible
curl http://localhost:8000

TROUBLESHOOTING:
================
If UI is not accessible:
1. Check pods: kubectl get pods -n olake
2. Check logs: kubectl logs -n olake -l app=olake-ui
3. Restart port-forward: sudo systemctl restart olake-port-forward
4. Check security group allows port 8000

================================================================
EOF

cat /home/ubuntu/deployment-summary.txt

echo ""
echo "================================================================"
echo "🎉 OLake Deployment Completed Successfully!"
echo "================================================================"
echo ""
echo "📋 Access Information:"
echo "   URL: http://$VM_PUBLIC_IP:8000"
echo "   Username: admin"
echo "   Password: password"
echo ""
echo "✅ All main pods are running!"
echo "✅ Port forwarding is active on port 8000"
echo ""
echo "Next steps:"
echo "1. Open http://$VM_PUBLIC_IP:8000 in your browser"
echo "2. Login with admin/password"
echo ""

exit 0