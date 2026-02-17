# Minikube Integration Guide for First Pipeline

Quick reference for using Minikube with this repository.

## Table of Contents
- [Quick Start](#quick-start)
- [Setup Methods](#setup-methods)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)

## Quick Start

### One-Command Setup
```bash
# Install Minikube, create cluster, and deploy app
scripts/minikube-setup.sh full-setup
```

### Access Your App
```bash
# Port forward
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# Open in browser
# http://localhost:8080
```

## Setup Methods

### Method 1: Automatic (Easiest)
```bash
scripts/minikube-setup.sh full-setup
```
- Installs Minikube CLI
- Creates cluster
- Deploys application
- Shows access methods

### Method 2: Step-by-Step
```bash
# Install
scripts/minikube-setup.sh install

# Create cluster
scripts/minikube-setup.sh create

# Deploy app
scripts/minikube-setup.sh deploy
```

### Method 3: With Local Docker Image
```bash
# Build locally
docker build -t first-pipeline:latest .

# Load into Minikube
scripts/minikube-setup.sh load-image first-pipeline:latest

# Deploy (after updating deployment.yaml to use local image)
kubectl apply -f k8s/
```

## Common Commands

### Cluster Management
```bash
# Check status
scripts/minikube-setup.sh status

# Start cluster
minikube start -p first-pipeline

# Stop cluster
scripts/minikube-setup.sh stop

# Delete cluster
scripts/minikube-setup.sh delete
```

### Deployment & Access
```bash
# Deploy application
scripts/minikube-setup.sh deploy

# Show access methods
scripts/minikube-setup.sh access

# Open dashboard
scripts/minikube-setup.sh dashboard

# View logs
scripts/minikube-setup.sh logs

# Test endpoint
scripts/minikube-setup.sh test
```

### Development
```bash
# SSH into Minikube
scripts/minikube-setup.sh ssh

# Load Docker image
scripts/minikube-setup.sh load-image <image-name>

# View logs
scripts/minikube-setup.sh logs

# Tail logs
kubectl logs -f -n first-pipeline -l app=first-pipeline
```

## File Structure

```
Lillteamet-first-pipeline/
├── minikube                      # Quick access script
├── MINIKUBE_SETUP.md             # Full Minikube guide
├── MINIKUBE_QUICK_REFERENCE.md  # This file
│
├── scripts/
│   ├── minikube-setup.sh         # Main Minikube setup script
│   └── k8s-deploy.sh             # General k8s deployment
│
├── k8s/                          # Kubernetes manifests
├── helm/                         # Helm charts
└── docker-compose.yml            # Local Docker dev
```

## Access Methods

### Port Forwarding (Recommended)
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
# http://localhost:8080
```

### Minikube Service
```bash
minikube service first-pipeline -n first-pipeline -p first-pipeline
# Automatically opens in browser
```

### NodePort
```bash
# Get Minikube IP
minikube ip -p first-pipeline

# Access on port 30000
# http://<minikube-ip>:30000
```

## Common Issues & Solutions

### Issue: "Cannot connect to Kubernetes cluster"

**Solution 1: Create cluster**
```bash
scripts/minikube-setup.sh create
```

**Solution 2: Start existing cluster**
```bash
minikube start -p first-pipeline
```

**Solution 3: Check status**
```bash
scripts/minikube-setup.sh status
```

### Issue: "Docker daemon not running"

**Solution**: Start Docker Desktop or Docker daemon
```bash
# macOS/Windows
# Open Docker Desktop

# Linux
sudo systemctl start docker
```

### Issue: "Insufficient memory"

**Solution: Allocate more memory**
```bash
minikube stop -p first-pipeline
minikube start -p first-pipeline --memory=4096
```

### Issue: "Image not found"

**Solution: Load local image**
```bash
docker build -t first-pipeline:latest .
scripts/minikube-setup.sh load-image first-pipeline:latest
```

### Issue: "Pod stuck in Pending"

**Solution: Check resources**
```bash
kubectl describe pod <pod-name> -n first-pipeline
minikube top nodes -p first-pipeline
```

## Performance Tips

### Minimal Setup (1GB RAM, 1 CPU)
```bash
minikube start -p first-pipeline --memory=1024 --cpus=1
```

### Standard Setup (2GB RAM, 2 CPU)
```bash
minikube start -p first-pipeline --memory=2048 --cpus=2
```

### Powerful Setup (4GB RAM, 4 CPU)
```bash
minikube start -p first-pipeline --memory=4096 --cpus=4
```

Enable metrics:
```bash
minikube addons enable metrics-server -p first-pipeline
```

## Development Workflow

### Live Reload Development

Terminal 1: Start Minikube
```bash
scripts/minikube-setup.sh deploy
```

Terminal 2: Port forward
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
```

Terminal 3: Watch logs
```bash
scripts/minikube-setup.sh logs
```

Terminal 4: Make changes and rebuild
```bash
# Edit code
# ...

# Rebuild image
docker build -t first-pipeline:dev .

# Load into Minikube
scripts/minikube-setup.sh load-image first-pipeline:dev

# Update deployment
kubectl set image deployment/first-pipeline \
  first-pipeline=first-pipeline:dev \
  -n first-pipeline

# Watch restart in Terminal 3
```

Terminal 5: Test changes
```bash
curl http://localhost:8080/status
```

## Integration with CI/CD

```bash
# On CI/CD server
scripts/minikube-setup.sh full-setup

# Run tests
kubectl run test --image=curlimages/curl -it --rm \
  -- curl http://first-pipeline.first-pipeline.svc.cluster.local/status

# Cleanup
scripts/minikube-setup.sh delete
```

## Related Documentation

- **Full Guide**: [MINIKUBE_SETUP.md](./MINIKUBE_SETUP.md)
- **Kubernetes Guide**: [DEPLOY_K8S.md](./DEPLOY_K8S.md)
- **Quick Start**: [START_HERE.md](./START_HERE.md)
- **Documentation Index**: [INDEX.md](./INDEX.md)

## Quick Commands Cheat Sheet

```bash
# Setup
scripts/minikube-setup.sh full-setup

# Check status
scripts/minikube-setup.sh status

# Deploy
scripts/minikube-setup.sh deploy

# Access
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# Logs
scripts/minikube-setup.sh logs

# Scale
kubectl scale deploy first-pipeline --replicas=5 -n first-pipeline

# Stop
scripts/minikube-setup.sh stop

# Delete
scripts/minikube-setup.sh delete

# Dashboard
scripts/minikube-setup.sh dashboard
```

---

**Ready?** Run: `scripts/minikube-setup.sh full-setup`

For detailed information, see [MINIKUBE_SETUP.md](./MINIKUBE_SETUP.md)
