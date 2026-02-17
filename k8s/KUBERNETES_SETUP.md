# Kubernetes Setup Guide

This directory contains Kubernetes manifests for deploying the First Pipeline application.

## Prerequisites

- Kubernetes cluster (1.24+) - local (Docker Desktop, minikube) or cloud
- `kubectl` CLI configured to access your cluster
- Docker image available (either pushed to a registry or local)

## Components

### 1. **namespace.yaml**
Creates a dedicated namespace `first-pipeline` for resource organization.

### 2. **configmap.yaml**
Contains environment variables:
- `PORT`: Application port (3000)
- `NODE_ENV`: Environment (production)

### 3. **deployment.yaml**
Main deployment with:
- **3 replicas** for high availability
- **Security context**: Runs as non-root user (UID 1001)
- **Liveness probe**: Restarts unhealthy pods
- **Readiness probe**: Removes unhealthy pods from traffic
- **Resource limits**: CPU and memory constraints
- **Volumes**: Empty directories for `/tmp` and `/app`

### 4. **service.yaml**
Two services:
- **ClusterIP**: Internal service for pod-to-pod communication
- **NodePort**: External access via node IP on port 30000

### 5. **hpa.yaml**
Horizontal Pod Autoscaler:
- Scales 2-10 replicas based on CPU (70%) and memory (80%) usage
- Smooth scaling with stabilization windows

## Quick Start

### Deploy All Resources

```bash
# Apply all manifests at once
kubectl apply -f k8s/

# Verify deployment
kubectl get all -n first-pipeline

# Check pod status
kubectl get pods -n first-pipeline -w

# View logs
kubectl logs -n first-pipeline -l app=first-pipeline -f
```

### Deploy Step-by-Step

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Create config
kubectl apply -f k8s/configmap.yaml

# 3. Deploy application
kubectl apply -f k8s/deployment.yaml

# 4. Create services
kubectl apply -f k8s/service.yaml

# 5. Enable auto-scaling
kubectl apply -f k8s/hpa.yaml
```

## Access the Application

### Internal (ClusterIP Service)
From within the cluster:
```bash
kubectl run -it --rm debug --image=alpine --restart=Never -- wget -O- http://first-pipeline.first-pipeline.svc.cluster.local/
```

### External (NodePort Service)
```bash
# Get node IP
kubectl get nodes -o wide

# Access via node IP (port 30000)
curl http://<node-ip>:30000/
```

### Port Forwarding
```bash
# Forward local port 8080 to pod port 3000
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# Access at http://localhost:8080
```

## Image Configuration

Before deploying, ensure the Docker image is available:

### Option 1: Use Local Docker Image (Docker Desktop/Minikube)
```bash
# Build image locally
docker build -t first-pipeline:latest .

# For Minikube, load into path
minikube image load first-pipeline:latest

# Update deployment.yaml image to: first-pipeline:latest
```

### Option 2: Use Registry Image (Recommended for Production)
```bash
# Build and push to GHCR
docker build -t ghcr.io/fchas/lillteamet-first-pipeline:latest .
docker push ghcr.io/fchas/lillteamet-first-pipeline:latest

# deployment.yaml already points to this image
```

## Monitoring & Debugging

### Check Deployment Status
```bash
kubectl describe deployment first-pipeline -n first-pipeline
```

### View Pod Events
```bash
kubectl describe pod <pod-name> -n first-pipeline
```

### Stream Logs
```bash
# All pods
kubectl logs -n first-pipeline -l app=first-pipeline -f

# Specific pod
kubectl logs -n first-pipeline <pod-name> -f
```

### Check HPA Status
```bash
kubectl get hpa -n first-pipeline
kubectl describe hpa first-pipeline-hpa -n first-pipeline
```

### Generate Load for HPA Testing
```bash
# In one terminal, port-forward
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# In another terminal, generate load
while true; do curl http://localhost:8080/; done
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace first-pipeline

# Or delete individual resources
kubectl delete -f k8s/
```

## Best Practices Implemented

✓ **Namespace isolation** - Resources in dedicated namespace  
✓ **Security** - Non-root user, read-only filesystem options, dropped capabilities  
✓ **Health checks** - Liveness and readiness probes  
✓ **Resource management** - CPU/memory requests and limits  
✓ **Scalability** - HPA for automatic scaling  
✓ **High availability** - 3 replicas by default  
✓ **Logging** - Standard output captured by kubelet  

## Troubleshooting

### Pods stuck in Pending
```bash
kubectl describe pod <pod-name> -n first-pipeline
# Check for insufficient resources, missing volumes, etc.
```

### CrashLoopBackOff
```bash
kubectl logs <pod-name> -n first-pipeline
# Review application logs for errors
```

### Image Pull Errors
```bash
# Verify image path in deployment.yaml
# Check image registry credentials if needed
kubectl get nodes -o wide  # Verify nodes can pull image
```

### Service not accessible
```bash
kubectl get svc -n first-pipeline
kubectl get endpoints -n first-pipeline
# Verify service selectors match pod labels
```
