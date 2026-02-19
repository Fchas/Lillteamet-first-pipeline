#!/bin/bash

###############################################################################
#                         FIRST PIPELINE SHUTDOWN                             #
#                                                                              #
# Cleanup script for Docker Compose and Kubernetes deployments                #
# Kills port forwards, removes pods, and performs factory reset               #
# Usage: ./shutdown.sh                                                       #
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

###############################################################################
# Cleanup Functions
###############################################################################

cleanup_docker_compose() {
    print_header "🐳 Stopping Docker Compose"
    
    print_section "Stopping Docker Compose services..."
    
    if docker-compose ps &>/dev/null 2>&1; then
        docker-compose down
        print_success "Docker Compose stopped"
    else
        print_info "Docker Compose not running or docker-compose not found"
    fi
}

cleanup_kubernetes() {
    print_header "☸️  Cleaning up Kubernetes"
    
    print_section "Killing port-forward processes..."
    
    # Kill any kubectl port-forward processes
    if pgrep -f "kubectl port-forward" > /dev/null; then
        pkill -f "kubectl port-forward" || true
        print_success "Killed port-forward processes"
    else
        print_info "No port-forward processes running"
    fi
    
    print_section "Checking Kubernetes cluster connection..."
    
    if ! kubectl cluster-info &>/dev/null; then
        print_info "Not connected to Kubernetes cluster"
        return 0
    fi
    
    print_success "Connected to Kubernetes cluster"
    
    print_section "Deleting first-pipeline namespace..."
    
    if kubectl get namespace first-pipeline &>/dev/null 2>&1; then
        print_info "Deleting namespace 'first-pipeline' (this will remove all pods and resources)..."
        kubectl delete namespace first-pipeline --ignore-not-found=true
        
        print_info "Waiting for namespace deletion..."
        kubectl wait --for=delete namespace/first-pipeline --timeout=30s 2>/dev/null || true
        
        print_success "Namespace deleted"
    else
        print_info "Namespace 'first-pipeline' not found"
    fi
}

cleanup_minikube() {
    print_header "🐳 Minikube Cleanup Options"
    
    if ! command -v minikube &> /dev/null; then
        print_info "Minikube not installed or not in PATH"
        return 0
    fi
    
    if ! minikube status -p first-pipeline &>/dev/null 2>&1; then
        print_info "Minikube cluster 'first-pipeline' not running"
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}Minikube cluster is running. Choose an option:${NC}"
    echo ""
    echo "  1) Keep cluster running (resources already cleaned)"
    echo "  2) Stop cluster (saves resources)"
    echo "  3) Delete cluster (factory reset)"
    echo ""
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            print_info "Keeping Minikube cluster running"
            ;;
        2)
            print_section "Stopping Minikube cluster..."
            minikube stop -p first-pipeline
            print_success "Minikube cluster stopped"
            ;;
        3)
            echo ""
            read -p "Are you sure you want to DELETE the cluster? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                print_section "Deleting Minikube cluster..."
                minikube delete -p first-pipeline
                print_success "Minikube cluster deleted"
            else
                print_info "Cluster deletion cancelled"
            fi
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
}

###############################################################################
# Main Menu
###############################################################################

show_menu() {
    print_header "🛑 First Pipeline Shutdown"
    
    echo ""
    print_section "Choose cleanup scope:"
    echo ""
    echo "  1) Full Cleanup (all of the below)"
    echo "  2) Docker Compose Only"
    echo "  3) Kubernetes Only (pods, port-forwards)"
    echo "  4) Advanced (choose each option)"
    echo "  5) Exit"
    echo ""
}

main() {
    while true; do
        show_menu
        
        read -p "Enter your choice (1-5): " choice
        
        echo ""
        
        case $choice in
            1)
                cleanup_docker_compose
                cleanup_kubernetes
                cleanup_minikube
                break
                ;;
            2)
                cleanup_docker_compose
                break
                ;;
            3)
                cleanup_kubernetes
                break
                ;;
            4)
                echo -e "${CYAN}Advanced Cleanup${NC}"
                echo ""
                
                read -p "Stop Docker Compose? (y/n): " dc
                if [ "$dc" = "y" ] || [ "$dc" = "Y" ]; then
                    cleanup_docker_compose
                fi
                
                echo ""
                
                read -p "Clean up Kubernetes (pods, port-forwards)? (y/n): " k8s
                if [ "$k8s" = "y" ] || [ "$k8s" = "Y" ]; then
                    cleanup_kubernetes
                fi
                
                echo ""
                
                read -p "Configure Minikube? (y/n): " mk
                if [ "$mk" = "y" ] || [ "$mk" = "Y" ]; then
                    cleanup_minikube
                fi
                
                break
                ;;
            5)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-5."
                sleep 1
                clear
                ;;
        esac
    done
    
    echo ""
    print_success "Cleanup complete!"
    echo ""
    print_info "Next steps:"
    echo "  • To restart: ./start.sh"
    echo "  • Check status: kubectl get all -n first-pipeline"
    echo "  • View Minikube status: minikube status"
    echo ""
}

###############################################################################
# Entry Point
###############################################################################

main "$@"
