# First Pipeline Helm Chart

Production-ready Helm chart for deploying the First Pipeline application to Kubernetes.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.0+

## Installation

### Simple Deployment

```bash
# Install with default values
helm install first-pipeline ./helm/first-pipeline

# Install with custom namespace
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace

# Install with custom values
helm install first-pipeline ./helm/first-pipeline -f custom-values.yaml
```

### Production Deployment

```bash
# With resource limits and autoscaling
helm install first-pipeline ./helm/first-pipeline \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10 \
  -n first-pipeline --create-namespace
```

## Upgrade

```bash
# Upgrade to new version
helm upgrade first-pipeline ./helm/first-pipeline

# Rollback to previous version
helm rollback first-pipeline 1
```

## Customization

Create a `custom-values.yaml`:

```yaml
replicaCount: 5

image:
  repository: your-registry/lillteamet-first-pipeline
  tag: v1.2.0

resources:
  requests:
    memory: "128Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "1000m"

service:
  type: LoadBalancer

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

Deploy with custom values:
```bash
helm install first-pipeline ./helm/first-pipeline -f custom-values.yaml
```

## Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | 3 | Number of pod replicas |
| `image.repository` | ghcr.io/fchas/lillteamet-first-pipeline | Docker image repository |
| `image.tag` | latest | Docker image tag |
| `config.port` | 3000 | Application port |
| `config.nodeEnv` | production | Node environment |
| `service.type` | ClusterIP | Service type (ClusterIP/NodePort/LoadBalancer) |
| `service.port` | 80 | Service port |
| `autoscaling.enabled` | true | Enable HPA |
| `autoscaling.minReplicas` | 2 | Minimum replicas |
| `autoscaling.maxReplicas` | 10 | Maximum replicas |
| `resources.requests.memory` | 64Mi | Memory request |
| `resources.requests.cpu` | 100m | CPU request |
| `resources.limits.memory` | 256Mi | Memory limit |
| `resources.limits.cpu` | 500m | CPU limit |

## Verification

```bash
# List releases
helm list

# Get release values
helm get values first-pipeline

# Get release manifest
helm get manifest first-pipeline

# Check deployment status
kubectl get all -n first-pipeline

# View release history
helm history first-pipeline
```

## Cleanup

```bash
# Uninstall release
helm uninstall first-pipeline

# Uninstall and delete namespace
helm uninstall first-pipeline -n first-pipeline
kubectl delete ns first-pipeline
```

## Advanced Examples

### Using private registry

```bash
# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=private-registry.com \
  --docker-username=user \
  --docker-password=password

# Use in Helm
helm install first-pipeline ./helm/first-pipeline \
  --set imagePullSecrets[0].name=regcred
```

### Enable Ingress

```bash
helm install first-pipeline ./helm/first-pipeline \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=first-pipeline.example.com \
  --set ingress.className=nginx
```

### Different environment per namespace

```bash
# Dev
helm install first-pipeline ./helm/first-pipeline \
  -n first-pipeline-dev --create-namespace \
  -f helm/first-pipeline/values-dev.yaml

# Staging
helm install first-pipeline ./helm/first-pipeline \
  -n first-pipeline-staging --create-namespace \
  -f helm/first-pipeline/values-staging.yaml

# Production
helm install first-pipeline ./helm/first-pipeline \
  -n first-pipeline-prod --create-namespace \
  -f helm/first-pipeline/values-prod.yaml
```
