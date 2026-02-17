# Minikube Setup Guide

Complete guide to setting up Minikube and deploying your First Pipeline application locally.

## What is Minikube?

Minikube is a tool that lets you run a full Kubernetes cluster locally on your machine. Perfect for:
- Local development and testing
- Learning Kubernetes
- CI/CD pipeline testing
- Before deploying to production

## Prerequisites

### System Requirements
- CPU: 2+ cores (4 recommended)
- RAM: 2GB minimum (4GB+ recommended)
- Storage: 10GB free space
- Docker or VirtualBox installed

### Software Requirements
- Docker Desktop installed and running
- kubectl CLI
- curl

## Installation

### Automatic Installation

```bash
# Run the full setup (installs everything and creates cluster)
scripts/minikube-setup.sh full-setup
```

### Manual Installation

#### Step 1: Install Minikube

**macOS (Homebrew)**
```bash
brew install minikube
```

**Windows (Chocolatey)**
```bash
choco install minikube
```

**Linux (Manual)**
```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
```

#### Step 2: Verify Installation
```bash
minikube version
kubectl version --client
```

#### Step 3: Create Minikube Cluster
```bash
minikube start --profile=first-pipeline --driver=docker --memory=2048 --cpus=2
```

#### Step 4: Configure kubectl
```bash
kubectl config use-context first-pipeline
kubectl cluster-info
```

## Quick Start

### One-Command Setup
```bash
# Install, create cluster, and deploy application
scripts/minikube-setup.sh full-setup
```

### Step-by-Step Setup

```bash
# 1. Create Minikube cluster
scripts/minikube-setup.sh create

# 2. Deploy application
scripts/minikube-setup.sh deploy

# 3. Access application
scripts/minikube-setup.sh access
```

## Available Commands

### Basic Operations

| Command | Purpose |
|---------|---------|
| `install` | Install Minikube CLI |
| `create` | Create new Minikube cluster |
| `deploy` | Deploy app to Minikube |
| `status` | Check cluster status |
| `stop` | Stop cluster (preserves state) |
| `delete` | Delete cluster completely |

### Development

| Command | Purpose |
|---------|---------|
| `load-image <image>` | Load Docker image into Minikube |
| `ssh` | SSH into Minikube VM |
| `dashboard` | Open Kubernetes dashboard |
| `logs` | View application logs |
| `test` | Test application endpoint |

### Example Usage

```bash
# Check cluster status
scripts/minikube-setup.sh status

# Build Docker image locally
docker build -t first-pipeline:latest .

# Load image into Minikube
scripts/minikube-setup.sh load-image first-pipeline:latest

# Update deployment.yaml to use local image
# deployment.yaml: image: first-pipeline:latest (with imagePullPolicy: Never)

# Deploy application
scripts/minikube-setup.sh deploy

# View logs
scripts/minikube-setup.sh logs

# Test endpoint
scripts/minikube-setup.sh test
```

## Accessing Your Application

### Method 1: Port Forwarding (Easiest)
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
```
Then open: **http://localhost:8080**

### Method 2: Minikube Service
```bash
# Automatically opens in browser
minikube service first-pipeline -n first-pipeline -p first-pipeline
```

### Method 3: NodePort
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip -p first-pipeline)

# Get NodePort
NODE_PORT=$(kubectl get svc -n first-pipeline first-pipeline-nodeport -o jsonpath='{.spec.ports[0].nodePort}')

# Access at
curl http://$MINIKUBE_IP:$NODE_PORT
```

## Common Tasks

### View Cluster Status
```bash
minikube status -p first-pipeline
kubectl get nodes
kubectl get pods -n first-pipeline
```

### Edit Deployment
```bash
kubectl edit deployment first-pipeline -n first-pipeline
```

### Scale Application
```bash
kubectl scale deployment first-pipeline --replicas=5 -n first-pipeline
```

### Watch HPA Scaling
```bash
# Terminal 1: Watch HPA
kubectl get hpa -n first-pipeline -w

# Terminal 2: Generate load
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
while true; do curl http://localhost:8080/; done
```

### View Logs
```bash
# All pods
kubectl logs -f -n first-pipeline -l app=first-pipeline

# Specific pod
kubectl logs -f -n first-pipeline <pod-name>

# Previous logs (if pod restarted)
kubectl logs -n first-pipeline <pod-name> --previous
```

### Describe Resources
```bash
kubectl describe deployment first-pipeline -n first-pipeline
kubectl describe pod <pod-name> -n first-pipeline
kubectl describe svc -n first-pipeline
```

### Delete Everything
```bash
scripts/minikube-setup.sh delete
```

## Troubleshooting

### Cluster Won't Start

**Error: "Unable to pull image"**
```bash
# Make sure Docker is running
docker ps

# Try again
scripts/minikube-setup.sh create
```

**Error: "Insufficient resources"**
```bash
# Increase memory/CPU
minikube start -p first-pipeline --memory=4096 --cpus=4
```

### Pods Won't Start

**Check pod status**
```bash
kubectl get pods -n first-pipeline
kubectl describe pod <pod-name> -n first-pipeline
kubectl logs <pod-name> -n first-pipeline
```

**Image not found**
```bash
# Load local image into Minikube
docker build -t first-pipeline:latest .
scripts/minikube-setup.sh load-image first-pipeline:latest

# Update deployment to use it
kubectl set image deployment/first-pipeline \
  first-pipeline=first-pipeline:latest \
  -n first-pipeline
```

### Can't Access Application

```bash
# Check service
kubectl get svc -n first-pipeline

# Check endpoints
kubectl get endpoints -n first-pipeline

# Test from inside cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  wget -O- http://first-pipeline.first-pipeline.svc.cluster.local/
```

### Out of Memory

```bash
# Stop and increase memory
minikube stop -p first-pipeline
minikube start -p first-pipeline --memory=4096

# Or delete and recreate
scripts/minikube-setup.sh delete
scripts/minikube-setup.sh create --memory=4096
```

## Configuration

### Cluster Settings

Edit these values in `scripts/minikube-setup.sh`:

```bash
CLUSTER_NAME="first-pipeline"    # Cluster name
MEMORY="2048"                     # Memory in MB
CPUS="2"                          # Number of CPUs
DRIVER="docker"                   # Driver (docker, virtualbox, etc)
```

### Use Different Driver

```bash
# VirtualBox
minikube start -p first-pipeline --driver=virtualbox

# Hyper-V (Windows)
minikube start -p first-pipeline --driver=hyperv

# KVM (Linux)
minikube start -p first-pipeline --driver=kvm2
```

## Dashboard

### Open Kubernetes Dashboard
```bash
scripts/minikube-setup.sh dashboard
```

Or manually:
```bash
minikube dashboard -p first-pipeline
```

This opens a web UI showing:
- All resources
- Pod logs
- Resource usage
- Events
- More detailed information

## Advanced Usage

### SSH into Minikube
```bash
scripts/minikube-setup.sh ssh
```

### Copy Files to/from Minikube
```bash
# Copy to Minikube
minikube cp /local/path first-pipeline:/remote/path

# Copy from Minikube
minikube cp first-pipeline:/remote/path /local/path
```

### Access Container Shell
```bash
kubectl exec -it <pod-name> -n first-pipeline -- /bin/sh
```

### Port Forward Multiple Services
```bash
kubectl port-forward -n first-pipeline pod/first-pipeline-xxx 8080:3000 &
kubectl port-forward -n first-pipeline svc/first-pipeline 8081:80 &
```

## Performance Tips

### Reduce Memory Usage
```bash
# Use less memory
minikube start -p first-pipeline --memory=1024 --cpus=1
```

### Enable Metrics Server
```bash
minikube addons enable metrics-server -p first-pipeline
```

### Enable Dashboard
```bash
minikube addons enable dashboard -p first-pipeline
```

### Disable Unused Addons
```bash
minikube addons list -p first-pipeline
minikube addons disable <addon-name> -p first-pipeline
```

## Integration with Development

### Local Docker Build
```bash
# Build image locally
docker build -t first-pipeline:dev .

# Load into Minikube
scripts/minikube-setup.sh load-image first-pipeline:dev

# Use in deployment
# deployment.yaml: image: first-pipeline:dev
# deployment.yaml: imagePullPolicy: Never
```

### Local Development Workflow

```bash
# Terminal 1: Start Minikube
scripts/minikube-setup.sh deploy

# Terminal 2: Watch for changes and rebuild
while inotifywait -e modify index.js; do
  docker build -t first-pipeline:dev .
  scripts/minikube-setup.sh load-image first-pipeline:dev
  kubectl rollout restart deployment/first-pipeline -n first-pipeline
done

# Terminal 3: View logs
scripts/minikube-setup.sh logs

# Terminal 4: Port forward
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
```

## Cleanup

### Stop Without Deleting
```bash
scripts/minikube-setup.sh stop

# Resume later
minikube start -p first-pipeline
```

### Delete Cluster
```bash
scripts/minikube-setup.sh delete
```

### Remove Minikube Completely
```bash
minikube delete --all      # Delete all clusters
brew uninstall minikube    # macOS
choco uninstall minikube   # Windows
sudo rm /usr/local/bin/minikube  # Linux
```

## Next Steps

1. **Deploy**: `scripts/minikube-setup.sh full-setup`
2. **Access**: `kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80`
3. **Explore**: Open http://localhost:8080
4. **Learn**: Read [DEPLOY_K8S.md](../DEPLOY_K8S.md) for more details

## Additional Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Support

For issues:
1. Check this guide's Troubleshooting section
2. Run `minikube logs -p first-pipeline`
3. Check [DEPLOY_K8S.md](../DEPLOY_K8S.md)
4. Open a GitHub issue

---

**Quick Command**
```bash
scripts/minikube-setup.sh full-setup
```

That's it! Kubernetes is ready on your local machine! 🎉
