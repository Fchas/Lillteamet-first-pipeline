#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="first-pipeline"
APP_NAME="first-pipeline"

print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    print_success "kubectl found"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker."
        exit 1
    fi
    print_success "Docker found"
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

# Build Docker image
build_image() {
    print_header "Building Docker Image"
    
    docker build -t ${APP_NAME}:latest .
    print_success "Docker image built: ${APP_NAME}:latest"
}

# Load image locally (for Docker Desktop/Minikube)
load_local_image() {
    print_header "Loading Image into Kubernetes"
    
    KUBECONFIG_CONTEXT=$(kubectl config current-context)
    
    if [[ "$KUBECONFIG_CONTEXT" == *"minikube"* ]]; then
        print_info "Detected Minikube context, loading image..."
        minikube image load ${APP_NAME}:latest
        print_success "Image loaded into Minikube"
    elif [[ "$KUBECONFIG_CONTEXT" == *"docker-desktop"* ]]; then
        print_info "Docker Desktop uses locally built images"
        print_success "Image available to Docker Desktop"
    else
        print_info "For remote clusters, push image to registry:"
        echo "  docker tag ${APP_NAME}:latest <registry>/${APP_NAME}:latest"
        echo "  docker push <registry>/${APP_NAME}:latest"
        echo "  Then update deployment.yaml image path"
    fi
}

# Deploy to Kubernetes
deploy_k8s() {
    print_header "Deploying to Kubernetes"
    
    kubectl apply -f k8s/namespace.yaml
    print_success "Namespace created"
    
    kubectl apply -f k8s/configmap.yaml
    print_success "ConfigMap created"
    
    kubectl apply -f k8s/deployment.yaml
    print_success "Deployment created"
    
    kubectl apply -f k8s/service.yaml
    print_success "Services created"
    
    kubectl apply -f k8s/hpa.yaml
    print_success "HPA created"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_header "Waiting for Deployment to be Ready"
    
    kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=5m
    print_success "Deployment is ready!"
}

# Show deployment info
show_info() {
    print_header "Deployment Information"
    
    print_info "Pods:"
    kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME}
    
    echo ""
    print_info "Services:"
    kubectl get svc -n ${NAMESPACE}
    
    echo ""
    print_info "HPA Status:"
    kubectl get hpa -n ${NAMESPACE}
    
    echo ""
    print_info "Access the application:"
    echo "  - Port Forward: kubectl port-forward -n ${NAMESPACE} svc/${APP_NAME} 8080:80"
    echo "  - NodePort (port 30000): kubectl get nodes -o wide | grep -i internal-ip"
}

# Main execution
main() {
    case "${1:-deploy}" in
        check)
            check_prerequisites
            ;;
        build)
            check_prerequisites
            build_image
            ;;
        load)
            load_local_image
            ;;
        deploy)
            check_prerequisites
            build_image
            load_local_image
            deploy_k8s
            wait_for_deployment
            show_info
            ;;
        restart)
            print_header "Restarting Deployment"
            kubectl rollout restart deployment/${APP_NAME} -n ${NAMESPACE}
            wait_for_deployment
            show_info
            ;;
        logs)
            kubectl logs -n ${NAMESPACE} -l app=${APP_NAME} -f
            ;;
        clean)
            print_header "Cleaning Up"
            kubectl delete namespace ${NAMESPACE}
            print_success "Namespace deleted"
            ;;
        *)
            echo "Usage: $0 {check|build|load|deploy|restart|logs|clean}"
            echo ""
            echo "Commands:"
            echo "  check   - Check prerequisites"
            echo "  build   - Build Docker image"
            echo "  load    - Load image into local Kubernetes"
            echo "  deploy  - Full deployment (build, load, deploy)"
            echo "  restart - Restart the deployment"
            echo "  logs    - Stream application logs"
            echo "  clean   - Delete all resources"
            exit 1
            ;;
    esac
}

main "$@"
