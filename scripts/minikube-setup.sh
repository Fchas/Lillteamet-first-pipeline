#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
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

# Configuration
CLUSTER_NAME="first-pipeline"
MEMORY="2048"
CPUS="2"
DRIVER="docker"

# Install Minikube
install_minikube() {
    print_header "Installing Minikube"
    
    if command -v minikube &> /dev/null; then
        print_success "Minikube already installed"
        minikube version
        return
    fi
    
    print_info "Downloading Minikube..."
    
    # Detect OS
    OS_TYPE="$(uname -s)"
    
    case "$OS_TYPE" in
        Linux*)
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
            chmod +x minikube-linux-amd64
            sudo mv minikube-linux-amd64 /usr/local/bin/minikube
            ;;
        Darwin*)
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-amd64
            chmod +x minikube-darwin-amd64
            sudo mv minikube-darwin-amd64 /usr/local/bin/minikube
            ;;
        MINGW*)
            choco install minikube -y
            ;;
        *)
            print_error "Unsupported OS: $OS_TYPE"
            exit 1
            ;;
    esac
    
    print_success "Minikube installed"
    minikube version
}

# Create Minikube cluster
create_cluster() {
    print_header "Creating Minikube Cluster"
    
    # Check if cluster already exists
    if minikube status -p "$CLUSTER_NAME" &>/dev/null; then
        print_success "Cluster '$CLUSTER_NAME' already exists"
        minikube status -p "$CLUSTER_NAME"
        return
    fi
    
    print_info "Creating cluster: $CLUSTER_NAME"
    print_info "Driver: $DRIVER, Memory: ${MEMORY}MB, CPUs: $CPUS"
    
    minikube start \
        --profile="$CLUSTER_NAME" \
        --driver="$DRIVER" \
        --memory="$MEMORY" \
        --cpus="$CPUS" \
        --container-runtime=docker \
        --enable-default-cni=true
    
    print_success "Minikube cluster created"
}

# Configure kubectl
configure_kubectl() {
    print_header "Configuring kubectl"
    
    # Set context
    kubectl config use-context "$CLUSTER_NAME"
    
    print_success "kubectl configured for Minikube"
    kubectl cluster-info
}

# Verify setup
verify_setup() {
    print_header "Verifying Setup"
    
    print_info "Cluster status:"
    minikube status -p "$CLUSTER_NAME"
    
    echo ""
    print_info "Nodes:"
    kubectl get nodes
    
    echo ""
    print_info "Available resources:"
    kubectl top nodes 2>/dev/null || print_info "Metrics not yet available"
}

# Load local Docker image into Minikube
load_image() {
    print_header "Loading Docker Image into Minikube"
    
    if [ -z "$1" ]; then
        print_error "Usage: Load Docker image into Minikube"
        print_info "Example: $0 load-image first-pipeline:latest"
        return 1
    fi
    
    IMAGE="$1"
    print_info "Loading image: $IMAGE"
    
    minikube -p "$CLUSTER_NAME" image load "$IMAGE"
    
    print_success "Image loaded: $IMAGE"
}

# Deploy to Minikube
deploy() {
    print_header "Deploying to Minikube"
    
    if ! minikube status -p "$CLUSTER_NAME" &>/dev/null; then
        print_error "Cluster not running. Create it first:"
        echo "  $0 create"
        exit 1
    fi
    
    configure_kubectl
    
    print_info "Deploying application..."
    kubectl apply -f k8s/
    
    print_success "Application deployed"
    
    echo ""
    print_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/first-pipeline -n first-pipeline --timeout=5m
    
    print_success "Deployment ready!"
}

# Show access info
show_access() {
    print_header "Accessing Your Application"
    
    # Get Minikube IP
    MINIKUBE_IP=$(minikube -p "$CLUSTER_NAME" ip)
    
    echo ""
    print_info "Option 1: Port Forward (Recommended)"
    echo "  kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80"
    echo "  Then open: http://localhost:8080"
    
    echo ""
    print_info "Option 2: NodePort (Using Minikube IP)"
    echo "  Minikube IP: $MINIKUBE_IP"
    echo "  NodePort: 30000"
    echo "  Open: http://$MINIKUBE_IP:30000"
    
    echo ""
    print_info "Option 3: Service URL"
    echo "  minikube -p $CLUSTER_NAME service first-pipeline -n first-pipeline"
}

# SSH into Minikube
ssh_cluster() {
    print_header "Accessing Minikube Shell"
    
    print_info "Connecting to Minikube cluster..."
    minikube -p "$CLUSTER_NAME" ssh
}

# Stop cluster
stop_cluster() {
    print_header "Stopping Minikube Cluster"
    
    minikube stop -p "$CLUSTER_NAME"
    print_success "Cluster stopped"
}

# Delete cluster
delete_cluster() {
    print_header "Deleting Minikube Cluster"
    
    print_error "Warning: This will delete the cluster and all data!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        minikube delete -p "$CLUSTER_NAME"
        print_success "Cluster deleted"
    else
        print_info "Cancelled"
    fi
}

# View dashboard
dashboard() {
    print_header "Opening Minikube Dashboard"
    
    print_info "Opening Kubernetes dashboard..."
    minikube -p "$CLUSTER_NAME" dashboard
}

# Main menu
main() {
    case "${1:-help}" in
        install)
            install_minikube
            ;;
        create)
            install_minikube
            create_cluster
            configure_kubectl
            verify_setup
            ;;
        deploy)
            deploy
            show_access
            ;;
        load-image)
            load_image "$2"
            ;;
        access)
            show_access
            ;;
        status)
            print_header "Cluster Status"
            minikube status -p "$CLUSTER_NAME"
            ;;
        ssh)
            ssh_cluster
            ;;
        stop)
            stop_cluster
            ;;
        delete)
            delete_cluster
            ;;
        dashboard)
            dashboard
            ;;
        logs)
            print_header "Application Logs"
            kubectl logs -f -n first-pipeline -l app=first-pipeline
            ;;
        test)
            print_header "Testing Application"
            kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80 &
            PF_PID=$!
            sleep 2
            
            print_info "Testing /status endpoint..."
            curl -s http://localhost:8080/status | jq . || curl http://localhost:8080/status
            
            kill $PF_PID 2>/dev/null || true
            print_success "Test complete"
            ;;
        full-setup)
            install_minikube
            create_cluster
            configure_kubectl
            verify_setup
            echo ""
            deploy
            echo ""
            show_access
            ;;
        *)
            echo "Minikube Setup Script for First Pipeline"
            echo ""
            echo "Usage: $0 {command}"
            echo ""
            echo "Commands:"
            echo "  install      - Install Minikube CLI"
            echo "  create       - Create Minikube cluster"
            echo "  deploy       - Deploy app to cluster"
            echo "  load-image   - Load Docker image into Minikube"
            echo "  access       - Show access methods"
            echo "  status       - Check cluster status"
            echo "  ssh          - SSH into cluster"
            echo "  stop         - Stop cluster"
            echo "  delete       - Delete cluster"
            echo "  dashboard    - Open Kubernetes dashboard"
            echo "  logs         - View application logs"
            echo "  test         - Test application endpoint"
            echo "  full-setup   - Run complete setup (all steps)"
            echo ""
            echo "Quick Start:"
            echo "  $0 full-setup"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
