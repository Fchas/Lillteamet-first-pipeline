# Kubernetes Setup Summary

Your repository is now fully configured for Kubernetes deployment! Here's what was added:

## 📦 What Was Created

### 1. **Kubernetes Manifests** (`k8s/` directory)
- `namespace.yaml` - Isolated namespace for the app
- `configmap.yaml` - Configuration (PORT, NODE_ENV)
- `deployment.yaml` - 3 replicas with security, probes, resource limits
- `service.yaml` - ClusterIP and NodePort services
- `hpa.yaml` - Horizontal Pod Autoscaler (2-10 replicas)
- `KUBERNETES_SETUP.md` - Complete k8s documentation

### 2. **Helm Charts** (`helm/` directory)
- `Chart.yaml` - Chart metadata
- `values.yaml` - Default configuration
- `templates/` - All k8s manifests as templates
- `HELM_USAGE.md` - Helm deployment guide

### 3. **Deployment Scripts** (`scripts/` directory)
- `k8s-deploy.sh` - Automated deployment helper with commands:
  - `check` - Verify prerequisites
  - `build` - Build Docker image
  - `load` - Load into Kubernetes
  - `deploy` - Full deployment
  - `restart` - Restart deployment
  - `logs` - Stream logs
  - `clean` - Delete resources

### 4. **Docker Compose** (`docker-compose.yml`)
- Local development setup with health checks

### 5. **Documentation**
- `DEPLOY_K8S.md` - Complete deployment guide
- Updated `README.md` - Quick start instructions

## 🚀 Quick Start (Choose One)

### Option 1: Automated (Easiest)
```bash
scripts/k8s-deploy.sh deploy
```

### Option 2: Helm (Recommended for Production)
```bash
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace
```

### Option 3: Raw Kubernetes
```bash
kubectl apply -f k8s/
```

### Option 4: Docker (Local Testing)
```bash
docker-compose up
```

## ✨ Features Included

✓ **High Availability** - 3 replicas by default  
✓ **Auto-Scaling** - HPA scales 2-10 pods based on CPU/memory  
✓ **Security** - Non-root user, read-only filesystem options, dropped capabilities  
✓ **Health Checks** - Liveness & readiness probes on `/status` endpoint  
✓ **Resource Management** - CPU/memory requests and limits  
✓ **Service Discovery** - Multiple service types (ClusterIP, NodePort)  
✓ **Configuration** - ConfigMap for environment variables  
✓ **Observability** - Structured logging, metrics-ready  

## 📋 File Structure

```
.
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose for local dev
├── README.md                     # Updated with k8s info
├── DEPLOY_K8S.md                 # Complete deployment guide
│
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   └── KUBERNETES_SETUP.md
│
├── helm/                         # Helm charts
│   ├── HELM_USAGE.md
│   └── first-pipeline/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── namespace.yaml
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── hpa.yaml
│           └── _helpers.tpl
│
└── scripts/                      # Deployment automation
    └── k8s-deploy.sh
```

## 🔧 Prerequisites

For Kubernetes deployment:
```bash
# Check prerequisites
kubectl version
helm version
docker --version
```

## 📖 Documentation

1. **Start Here**: [README.md](../README.md)
2. **For Kubernetes Details**: [DEPLOY_K8S.md](../DEPLOY_K8S.md)
3. **For Raw k8s Manifests**: [k8s/KUBERNETES_SETUP.md](../k8s/KUBERNETES_SETUP.md)
4. **For Helm Deployments**: [helm/HELM_USAGE.md](../helm/HELM_USAGE.md)

## 💡 Common Tasks

### Deploy to Kubernetes
```bash
scripts/k8s-deploy.sh deploy
```

### View Running Pods
```bash
kubectl get pods -n first-pipeline
```

### Access Application
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
# Access at http://localhost:8080
```

### View Logs
```bash
kubectl logs -f -n first-pipeline -l app=first-pipeline
```

### Scale Manually
```bash
kubectl scale deploy first-pipeline --replicas=5 -n first-pipeline
```

### Restart Deployment
```bash
scripts/k8s-deploy.sh restart
```

### Clean Up
```bash
scripts/k8s-deploy.sh clean
```

## 🌐 Deployment Environments

The setup works with:
- **Local**: Docker Desktop, Minikube, kind
- **Cloud**: EKS, GKE, AKS, Digital Ocean Kubernetes, etc.

## 🔐 Security Features

- Non-root user execution (UID 1001)
- Capability dropping
- Resource limits to prevent resource exhaustion
- Health checks to remove unhealthy pods from traffic
- Proper service isolation with namespace

## 📊 Monitoring Ready

The setup includes:
- Health checks on `/status` endpoint
- Resource requests/limits for metrics
- HPA based on CPU and memory usage
- Ready for integration with Prometheus, Grafana, etc.

## 🐛 Troubleshooting

If something doesn't work:

1. **Check pod status**
   ```bash
   kubectl get pods -n first-pipeline
   kubectl describe pod <pod-name> -n first-pipeline
   ```

2. **View logs**
   ```bash
   kubectl logs <pod-name> -n first-pipeline
   ```

3. **Test endpoint**
   ```bash
   kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
   curl http://localhost:8080/status
   ```

## 🎯 Next Steps

1. Review [DEPLOY_K8S.md](../DEPLOY_K8S.md) for detailed information
2. Choose your deployment method
3. Run the deployment
4. Verify with `kubectl get all -n first-pipeline`
5. Access the application via port-forward or service IP

## 📝 Notes

- The Docker image is referenced as `ghcr.io/fchas/lillteamet-first-pipeline:latest`
- For local k8s clusters, use the deployment script which handles local images
- For cloud deployments, ensure the image is pushed to a registry
- All resources are in the `first-pipeline` namespace by default

---

**Need help?** Check the documentation files or run:
```bash
scripts/k8s-deploy.sh check  # Verify prerequisites
scripts/k8s-deploy.sh        # See all available commands
```
