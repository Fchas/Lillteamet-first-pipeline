# First Pipeline Challenge

[![CI/CD Pipeline](https://github.com/Fchas/Lillteamet-first-pipeline/actions/workflows/pipeline.yml/badge.svg)](https://github.com/Fchas/Lillteamet-first-pipeline/actions/workflows/pipeline.yml)

Live deployment: https://lillteamet-first-pipeline.onrender.com/

## About
Week 4 Boiler Room Hackathon - Building a complete CI/CD pipeline with Docker and Kubernetes support.

## 🚀 Quick Start (Easiest Way)

### Just Run This Command
```bash
# Linux/macOS
./start.sh

# Windows
start.bat
```

**That's it!** Choose your deployment method from the interactive menu.

---

## Alternative Quick Start Methods

### Docker Compose (Local Development)
```bash
# Build and run with Docker
docker build -t first-pipeline:latest .
docker run -p 3000:3000 first-pipeline:latest

# Or use docker-compose
docker-compose up
```

### Minikube (Local Kubernetes)
```bash
# Quick setup: Install, create cluster, and deploy
scripts/minikube-setup.sh full-setup

# Or access the app after deployment
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
# Open http://localhost:8080
```

### Kubernetes (Production)
```bash
# Deploy all resources
kubectl apply -f k8s/

# Or with Helm (Recommended)
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace
```

## 🛑 Cleanup & Shutdown

Need to stop everything or do a factory reset?

```bash
# Linux/macOS
./shutdown.sh

# Windows
shutdown.bat
```

Choose from:
- **Full Cleanup** - Stop Docker Compose + delete K8s namespace + configure Minikube
- **Docker Compose Only** - Stop just Docker Compose
- **Kubernetes Only** - Kill port-forwards and remove pods
- **Advanced** - Pick exactly what to clean

---

## Architecture

### Docker Architecture
```
Code Push → GitHub Actions → Tests → Docker Build → Trivy Scan → Deploy
```

### Kubernetes Architecture
```
Docker Image → k8s Manifest / Helm → kubectl apply → Deployment
                                   → Services
                                   → HPA (Auto-scaling)
```

## Deployment Options

| Method | Use Case | Complexity |
|--------|----------|-----------|
| **Docker** | Local development, quick testing | Low |
| **Kubernetes (YAML)** | Learning k8s, small deployments | Medium |
| **Kubernetes (Helm)** | Production, templating, GitOps | Medium-High |

## Features

### Docker
- ✓ Multi-stage builds
- ✓ Non-root user execution
- ✓ Health checks
- ✓ Small image size (Alpine)

### Kubernetes
- ✓ 3 replicas for high availability
- ✓ Security context (non-root, read-only)
- ✓ Liveness & readiness probes
- ✓ Horizontal Pod Autoscaler (2-10 replicas)
- ✓ Resource limits & requests
- ✓ ServiceDiscovery
- ✓ ConfigMap for configuration

### Helm
- ✓ Templated deployments
- ✓ Easy customization per environment
- ✓ Version control
- ✓ Rollback capability

## Documentation

- [K8s Setup Guide](./k8s/KUBERNETES_SETUP.md) - Detailed Kubernetes deployment
- [Helm Usage](./helm/HELM_USAGE.md) - Helm chart documentation
- [Deployment Script](./scripts/k8s-deploy.sh) - Automated deployment helper

## Status
✓ All tests passing
✓ Security scan complete
✓ Docker support
✓ Kubernetes ready
✓ Helm charts included
✓ Deployed to production

## File Structure
```
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Local development setup
├── package.json                  # Node.js dependencies
├── index.js                      # Express application
├── test.js                       # Test suite
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
│   └── first-pipeline/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
└── scripts/
    └── k8s-deploy.sh             # Deployment automation
```
