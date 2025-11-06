#!/bin/bash
set -e

echo "=== Starting Minikube Setup ==="
echo "Timestamp: $(date)"

echo "=== Starting Minikube cluster ==="
minikube start \
    --cpus=3 \
    --memory=6144 \
    --driver=docker \
    --disk-size=40g \
    --kubernetes-version=stable

echo "=== Waiting for Minikube to be ready ==="
minikube status

echo "=== Enabling Minikube addons ==="
minikube addons enable ingress
minikube addons enable storage-provisioner
minikube addons enable metrics-server

echo "=== Verifying addons ==="
minikube addons list

echo "=== Waiting for system pods ==="
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

echo "=== Verifying storage class ==="
kubectl get storageclass

echo "=== Cluster information ==="
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

cp ~/.kube/config ~/.kube/config.backup

echo "=== Minikube setup completed ==="
echo "Timestamp: $(date)"