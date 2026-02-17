# Kubernetes Deployment Guide for First Pipeline

This document provides a complete overview of deploying the First Pipeline application to Kubernetes.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Methods](#deployment-methods)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Production Checklist](#production-checklist)

## Overview

The First Pipeline application now supports three deployment methods:

1. **Docker** - Traditional containerization for local development
2. **Kubernetes (Raw YAML)** - Direct k8s manifest deployment
3. **Kubernetes (Helm)** - Production-grade templated deployment

All three approaches use the same Docker image, ensuring consistency across environments.

## Prerequisites

### For Docker Deployments
- Docker Desktop / Docker Engine installed
- `docker` CLI available

### For Kubernetes Deployments
- Kubernetes cluster (1.24+)
- `kubectl` CLI configured
- `helm` CLI (for Helm deployments)

### Supported Kubernetes Environments
- **Local**: Docker Desktop, Minikube, kind
- **Cloud**: EKS (AWS), GKE (Google), AKS (Azure), Digital Ocean, etc.

## Deployment Methods

### Method 1: Docker (Fastest for Local Testing)

```bash
# Build image
docker build -t first-pipeline:latest .

# Run container
docker run -p 3000:3000 first-pipeline:latest

# Or use docker-compose
docker-compose up
```

**Pros**: Simple, lightweight, instant feedback  
**Cons**: Single instance, no auto-scaling, no service discovery

### Method 2: Kubernetes Raw YAML (Best for Learning)

```bash
# Deploy everything at once
kubectl apply -f k8s/

# Or deploy step by step
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

**Pros**: Full control, educational, transparent  
**Cons**: Manual updates, harder to manage multiple environments

### Method 3: Helm (Recommended for Production)

```bash
# Deploy with defaults
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace

# Deploy with customization
helm install first-pipeline ./helm/first-pipeline \
  -n first-pipeline --create-namespace \
  -f helm/first-pipeline/values.yaml
```

**Pros**: Templating, environment management, version control, easy rollback  
**Cons**: Slight learning curve for Helm concepts

### Method 4: Automated Script (Simplest)

```bash
# Uses script to automate everything
scripts/k8s-deploy.sh deploy

# Or individual commands
scripts/k8s-deploy.sh build    # Build Docker image
scripts/k8s-deploy.sh load     # Load into k8s
scripts/k8s-deploy.sh deploy   # Full deployment
scripts/k8s-deploy.sh restart  # Restart deployment
scripts/k8s-deploy.sh logs     # Stream logs
scripts/k8s-deploy.sh clean    # Delete resources
```

## Step-by-Step Deployment

### Complete Deployment from Scratch

#### Step 1: Prepare Your Kubernetes Cluster

```bash
# Verify cluster connection
kubectl cluster-info

# Check available nodes
kubectl get nodes

# Create namespace (if using raw YAML)
kubectl create namespace first-pipeline
```

#### Step 2: Build and Push Docker Image

```bash
# Option A: Using script
scripts/k8s-deploy.sh build

# Option B: Manual
docker build -t ghcr.io/fchas/lillteamet-first-pipeline:latest .
docker push ghcr.io/fchas/lillteamet-first-pipeline:latest
```

#### Step 3: Deploy to Kubernetes

**Option A - Using Script (Simplest)**
```bash
scripts/k8s-deploy.sh deploy
```

**Option B - Using Helm (Recommended)**
```bash
helm install first-pipeline ./helm/first-pipeline \
  -n first-pipeline --create-namespace
```

**Option C - Using Raw YAML**
```bash
kubectl apply -f k8s/
```

#### Step 4: Verify Deployment

```bash
# Check namespace
kubectl get ns

# Check deployments
kubectl get deployments -n first-pipeline

# Check pods
kubectl get pods -n first-pipeline

# Check services
kubectl get svc -n first-pipeline

# Check HPA
kubectl get hpa -n first-pipeline
```

#### Step 5: Access the Application

**Port Forward (Easiest)**
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
# Access at http://localhost:8080
```

**NodePort (Requires node IP)**
```bash
# Get node IP
kubectl get nodes -o wide

# Access at http://<node-ip>:30000
```

**LoadBalancer (Cloud environments)**
```bash
# Get external IP (may take a minute)
kubectl get svc -n first-pipeline

# Access at http://<external-ip>
```

## Verification

### Health Checks

```bash
# Test status endpoint
curl http://localhost:8080/status

# Expected response
{
  "status": "ok",
  "timestamp": "2026-02-17T10:30:00.000Z"
}
```

### Pod Health

```bash
# Check liveness probes are working
kubectl describe pod <pod-name> -n first-pipeline | grep -A 5 "Liveness"

# Check readiness probes are working
kubectl describe pod <pod-name> -n first-pipeline | grep -A 5 "Readiness"
```

### Logs

```bash
# Stream logs from all pods
kubectl logs -f -n first-pipeline -l app=first-pipeline

# Stream logs from specific pod
kubectl logs -f -n first-pipeline <pod-name>

# View previous logs (if pod restarted)
kubectl logs -n first-pipeline <pod-name> --previous
```

### Metrics

```bash
# View HPA status
kubectl get hpa -n first-pipeline

# Detailed HPA info
kubectl describe hpa first-pipeline-hpa -n first-pipeline

# Test autoscaling (in another terminal)
# 1. Port forward:
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# 2. Generate load:
while true; do curl http://localhost:8080/; done

# 3. Watch HPA scale up:
kubectl get hpa -n first-pipeline -w
```

## Troubleshooting

### Pods Won't Start (Pending State)

```bash
# Check events and detailed description
kubectl describe pod <pod-name> -n first-pipeline

# Common causes:
# 1. Insufficient resources
kubectl describe nodes

# 2. Image pull errors
kubectl logs <pod-name> -n first-pipeline

# 3. ConfigMap missing
kubectl get configmap -n first-pipeline
```

### Pods Crashing (CrashLoopBackOff)

```bash
# Check logs
kubectl logs <pod-name> -n first-pipeline

# Check current and previous logs
kubectl logs <pod-name> -n first-pipeline --previous

# Verify environment variables
kubectl exec -it <pod-name> -n first-pipeline -- env

# Verify health checks
kubectl describe pod <pod-name> -n first-pipeline
```

### Can't Access Application

```bash
# Verify service exists and has endpoints
kubectl get svc -n first-pipeline
kubectl get endpoints -n first-pipeline

# Verify pod selectors match service
kubectl get pods -n first-pipeline --show-labels

# Test from inside cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  wget -O- http://first-pipeline.first-pipeline.svc.cluster.local/

# Check network policies
kubectl get networkpolicies -n first-pipeline
```

### Port Forward Issues

```bash
# Kill hanging port-forwards
pkill -f "port-forward"

# Start fresh
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
```

## Production Checklist

Before deploying to production, ensure:

### Kubernetes Configuration
- [ ] Resource requests and limits are set appropriately
- [ ] Health checks (liveness & readiness) are configured
- [ ] HPA is enabled with appropriate thresholds
- [ ] Multiple replicas are configured (minimum 3)
- [ ] Security context is enforced (non-root user)

### Container Image
- [ ] Image tagged with version number (not just `latest`)
- [ ] Image pushed to private/secure registry
- [ ] Image pulls configured correctly
- [ ] Security scanning completed (Trivy, etc.)

### Networking
- [ ] Service type is appropriate (ClusterIP/LoadBalancer)
- [ ] Ingress configured if needed
- [ ] Network policies configured for security

### Monitoring & Logging
- [ ] Log aggregation configured
- [ ] Monitoring/alerting set up
- [ ] Metrics exported for observability

### Deployment Strategy
- [ ] Helm/GitOps tools configured
- [ ] Blue-green or rolling deployments planned
- [ ] Rollback strategy documented

### Secrets & Configuration
- [ ] Sensitive data in Secrets (not ConfigMap)
- [ ] ConfigMap for non-sensitive config
- [ ] Secret rotation policy established

### Persistence & Data
- [ ] Persistent volumes configured if needed
- [ ] Backup strategy for persistent data
- [ ] Database migrations planned

### Documentation
- [ ] Runbook for common operations created
- [ ] Team trained on deployments
- [ ] Incident response procedures documented

## Quick Reference

### Common Commands

```bash
# View all resources
kubectl get all -n first-pipeline

# Describe deployment
kubectl describe deploy first-pipeline -n first-pipeline

# View rollout history
kubectl rollout history deploy first-pipeline -n first-pipeline

# Rollback to previous version
kubectl rollout undo deploy first-pipeline -n first-pipeline

# Scale manually
kubectl scale deploy first-pipeline --replicas=5 -n first-pipeline

# Delete deployment
kubectl delete deploy first-pipeline -n first-pipeline

# Shell into pod
kubectl exec -it <pod-name> -n first-pipeline -- /bin/sh

# Copy file from pod
kubectl cp first-pipeline/<pod-name>:/app/file.txt ./file.txt

# Port forward
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# Watch pods
kubectl get pods -n first-pipeline -w

# Tail logs
kubectl logs -f -n first-pipeline -l app=first-pipeline --all-containers=true
```

### Helm Commands

```bash
# List releases
helm list -n first-pipeline

# Get release values
helm get values first-pipeline -n first-pipeline

# Upgrade release
helm upgrade first-pipeline ./helm/first-pipeline -n first-pipeline

# Rollback release
helm rollback first-pipeline 1 -n first-pipeline

# Delete release
helm uninstall first-pipeline -n first-pipeline
```

## Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Charts Documentation](https://helm.sh/docs/)
- [Best Practices](./k8s/KUBERNETES_SETUP.md)
- [Helm Guide](./helm/HELM_USAGE.md)

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs with `kubectl logs`
3. Describe resources with `kubectl describe`
4. Check GitHub Issues: https://github.com/Fchas/Lillteamet-first-pipeline/issues
