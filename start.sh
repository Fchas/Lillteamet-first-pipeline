#!/bin/bash

###############################################################################
#                         FIRST PIPELINE STARTUP                              #
#                                                                              #
# Simple startup script for Docker and Kubernetes deployment options          #
# Usage: ./start.sh                                                           #
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="first-pipeline"
NAMESPACE="first-pipeline"

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "\n${CYAN}► $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_option() {
    echo -e "  ${CYAN}$1)${NC} $2"
}

###############################################################################
# Checks
###############################################################################

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker Desktop or Docker Engine."
        return 1
    fi
    
    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        return 1
    fi
    
    return 0
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        return 1
    fi
    return 0
}

check_minikube() {
    if ! command -v minikube &> /dev/null; then
        return 1
    fi
    return 0
}

check_helm() {
    if ! command -v helm &> /dev/null; then
        return 1
    fi
    return 0
}

###############################################################################
# Deployment Options
###############################################################################

start_docker_compose() {
    print_header "🐳 Docker Compose Setup"
    
    print_section "Checking prerequisites..."
    if ! check_docker; then
        print_error "Docker is required for this option"
        return 1
    fi
    
    print_success "Docker is ready"
    
    print_section "Starting application with Docker Compose..."
    print_info "Building and starting containers..."
    
    cd "$REPO_ROOT"
    docker-compose up -d
    
    print_success "Docker Compose is running!"
    
    echo ""
    print_section "Access Information:"
    echo -e "  URL: ${GREEN}http://localhost:3000${NC}"
    echo -e "  Status: ${GREEN}http://localhost:3000/status${NC}"
    
    echo ""
    print_section "Useful Commands:"
    echo "  View logs:     docker-compose logs -f"
    echo "  Stop:          docker-compose down"
    echo "  Rebuild:       docker-compose up --build"
    
    echo ""
    print_info "Application is ready! Opening in 5 seconds..."
    sleep 5
    
    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:3000"
    elif command -v open &> /dev/null; then
        open "http://localhost:3000"
    fi
}

start_minikube() {
    print_header "🐳 Minikube (Local Kubernetes)"
    
    print_section "Checking prerequisites..."
    if ! check_docker; then
        print_error "Docker is required"
        return 1
    fi
    print_success "Docker ready"
    
    if ! check_kubectl; then
        print_error "kubectl is required"
        return 1
    fi
    print_success "kubectl ready"
    
    print_section "Starting Minikube deployment..."
    
    cd "$REPO_ROOT"
    
    # Run the Minikube setup script
    if [ -f "scripts/minikube-setup.sh" ]; then
        bash scripts/minikube-setup.sh full-setup
        
        echo ""
        print_success "Minikube deployment complete!"
        
        echo ""
        print_section "Access Information:"
        echo "  Use port-forward:"
        echo -e "    ${CYAN}kubectl port-forward -n $NAMESPACE svc/$PROJECT_NAME 8080:80${NC}"
        echo "  Then open: http://localhost:8080"
        
        echo ""
        print_section "Useful Commands:"
        echo "  View logs:     kubectl logs -f -n $NAMESPACE -l app=$PROJECT_NAME"
        echo "  Dashboard:     $REPO_ROOT/scripts/minikube-setup.sh dashboard"
        echo "  Stop:          $REPO_ROOT/scripts/minikube-setup.sh stop"
        echo "  Delete:        $REPO_ROOT/scripts/minikube-setup.sh delete"
    else
        print_error "Minikube setup script not found"
        return 1
    fi
}

start_kubernetes() {
    print_header "🐳 Kubernetes (Production)"
    
    print_section "Checking prerequisites..."
    if ! check_kubectl; then
        print_error "kubectl is required"
        return 1
    fi
    print_success "kubectl ready"
    
    # Check if connected to a cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Please ensure you have:"
        echo "  1. A Kubernetes cluster running (EKS, GKE, AKS, etc.)"
        echo "  2. kubectl configured with valid credentials"
        echo ""
        print_info "Or use Minikube for local testing"
        return 1
    fi
    print_success "Kubernetes cluster connected"
    
    print_section "Starting Kubernetes deployment..."
    
    cd "$REPO_ROOT"
    
    if [ -f "scripts/k8s-deploy.sh" ]; then
        bash scripts/k8s-deploy.sh deploy
        
        echo ""
        print_success "Kubernetes deployment complete!"
        
        echo ""
        print_section "Access Information:"
        echo "  Use port-forward:"
        echo -e "    ${CYAN}kubectl port-forward -n $NAMESPACE svc/$PROJECT_NAME 8080:80${NC}"
        echo "  Then open: http://localhost:8080"
        
        echo ""
        print_section "Useful Commands:"
        echo "  View logs:     kubectl logs -f -n $NAMESPACE -l app=$PROJECT_NAME"
        echo "  Scale:         kubectl scale deploy $PROJECT_NAME --replicas=5 -n $NAMESPACE"
        echo "  Delete:        kubectl delete namespace $NAMESPACE"
    else
        print_error "k8s deployment script not found"
        return 1
    fi
}

start_helm() {
    print_header "📦 Kubernetes with Helm (Production Recommended)"
    
    print_section "Checking prerequisites..."
    if ! check_kubectl; then
        print_error "kubectl is required"
        return 1
    fi
    print_success "kubectl ready"
    
    if ! check_helm; then
        print_error "Helm is required but not found. Please install Helm."
        return 1
    fi
    print_success "Helm ready"
    
    # Check if connected to a cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Please ensure you have a Kubernetes cluster running"
        return 1
    fi
    print_success "Kubernetes cluster connected"
    
    print_section "Deploying with Helm..."
    
    cd "$REPO_ROOT"
    
    print_info "Installing Helm chart..."
    helm install "$PROJECT_NAME" ./helm/"$PROJECT_NAME" \
        -n "$NAMESPACE" --create-namespace
    
    print_success "Helm deployment complete!"
    
    echo ""
    print_section "Access Information:"
    echo "  Use port-forward:"
    echo -e "    ${CYAN}kubectl port-forward -n $NAMESPACE svc/$PROJECT_NAME 8080:80${NC}"
    echo "  Then open: http://localhost:8080"
    
    echo ""
    print_section "Useful Commands:"
    echo "  View release:  helm list -n $NAMESPACE"
    echo "  Upgrade:       helm upgrade $PROJECT_NAME ./helm/$PROJECT_NAME -n $NAMESPACE"
    echo "  Rollback:      helm rollback $PROJECT_NAME -n $NAMESPACE"
    echo "  Delete:        helm uninstall $PROJECT_NAME -n $NAMESPACE"
}

###############################################################################
# Main Menu
###############################################################################

show_menu() {
    print_header "🚀 First Pipeline Startup"
    
    echo ""
    print_section "Choose your deployment method:"
    echo ""
    print_option "1" "Docker Compose (Local Development) - Fast, Simple"
    print_option "2" "Minikube (Local Kubernetes) - Full k8s locally"
    print_option "3" "Kubernetes (Production) - Use existing cluster"
    print_option "4" "Helm (Production Recommended) - Templated deployment"
    print_option "5" "View Documentation"
    print_option "6" "Exit"
    echo ""
}

show_documentation() {
    print_header "📚 Documentation"
    
    echo ""
    echo "Available Guides:"
    echo "  • README.md - Project overview"
    echo "  • START_HERE.md - Getting started"
    echo "  • MINIKUBE_QUICK_REFERENCE.md - Minikube quick ref"
    echo "  • MINIKUBE_SETUP.md - Minikube full guide"
    echo "  • DEPLOY_K8S.md - Kubernetes deployment guide"
    echo "  • INDEX.md - Master documentation index"
    echo "  • K8S_QUICK_START.md - Quick Kubernetes reference"
    echo ""
    
    read -p "Press Enter to return to menu..."
}

###############################################################################
# Main Loop
###############################################################################

main() {
    while true; do
        show_menu
        
        read -p "Enter your choice (1-6): " choice
        
        echo ""
        
        case $choice in
            1)
                start_docker_compose
                break
                ;;
            2)
                start_minikube
                break
                ;;
            3)
                start_kubernetes
                break
                ;;
            4)
                start_helm
                break
                ;;
            5)
                show_documentation
                ;;
            6)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-6."
                sleep 1
                clear
                ;;
        esac
    done
    
    echo ""
    print_success "Setup complete! Your application is ready!"
    echo ""
    print_info "Next steps:"
    echo "  1. Open http://localhost:3000 (Docker) or http://localhost:8080 (k8s)"
    echo "  2. Run tests: npm test"
    echo "  3. View logs for your chosen deployment method"
    echo ""
    print_info "For more information, see the documentation files."
}

###############################################################################
# Entry Point
###############################################################################

# Make scripts executable
chmod +x "$REPO_ROOT/scripts/k8s-deploy.sh" 2>/dev/null || true
chmod +x "$REPO_ROOT/scripts/minikube-setup.sh" 2>/dev/null || true

# Run main menu
main "$@"
