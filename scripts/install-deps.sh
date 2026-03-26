#!/usr/bin/env bash
set -euo pipefail

# Portable dependency installer for this repository.
# Supports: apt, dnf, yum, pacman, zypper, brew

REQUIRED_TOOLS=(git curl node npm docker terraform kubectl helm)
OPTIONAL_TOOLS=(minikube)

info() { printf '[INFO] %s\n' "$*"; }
success() { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
error() { printf '[ERR]  %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Use sudo only when needed and available.
SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  if have sudo; then
    SUDO="sudo"
  else
    error "This script needs root privileges for package installs (sudo not found)."
    exit 1
  fi
fi

PKG_MANAGER=""
if have apt-get; then
  PKG_MANAGER="apt"
elif have dnf; then
  PKG_MANAGER="dnf"
elif have yum; then
  PKG_MANAGER="yum"
elif have pacman; then
  PKG_MANAGER="pacman"
elif have zypper; then
  PKG_MANAGER="zypper"
elif have brew; then
  PKG_MANAGER="brew"
else
  error "No supported package manager found (apt/dnf/yum/pacman/zypper/brew)."
  exit 1
fi

info "Detected package manager: ${PKG_MANAGER}"

install_with_apt() {
  $SUDO apt-get update
  # Base tools available in Debian/Ubuntu/Kali repos.
  $SUDO apt-get install -y git curl ca-certificates gnupg lsb-release \
    nodejs npm docker.io docker-compose kubectl helm || true

  # Terraform is not available in all apt repos by default.
  if ! have terraform; then
    warn "Terraform not found after apt install. Attempting HashiCorp apt repo setup."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      | $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    $SUDO apt-get update
    $SUDO apt-get install -y terraform || true
  fi

  # Minikube optional.
  $SUDO apt-get install -y minikube || true

  # Start docker daemon when available.
  if have systemctl; then
    $SUDO systemctl enable --now docker || true
  fi
}

install_with_dnf() {
  $SUDO dnf -y install git curl nodejs npm docker terraform kubernetes-client helm || true
  $SUDO dnf -y install minikube || true
  $SUDO systemctl enable --now docker || true
}

install_with_yum() {
  $SUDO yum -y install git curl nodejs npm docker terraform kubectl helm || true
  $SUDO yum -y install minikube || true
  $SUDO systemctl enable --now docker || true
}

install_with_pacman() {
  $SUDO pacman -Sy --noconfirm git curl nodejs npm docker docker-compose terraform kubectl helm minikube || true
  $SUDO systemctl enable --now docker || true
}

install_with_zypper() {
  $SUDO zypper --non-interactive install git curl nodejs npm docker terraform kubectl helm minikube || true
  $SUDO systemctl enable --now docker || true
}

install_with_brew() {
  # On macOS/Linux brew installs cli tools. Docker Desktop may still be needed on macOS.
  brew update
  brew install git curl node terraform kubectl helm minikube docker docker-compose || true
  if [ "$(uname -s)" = "Darwin" ]; then
    brew install --cask docker || true
    warn "If Docker commands fail, open Docker Desktop once to start the daemon."
  else
    warn "On Linux, brew 'docker' is often CLI only. Ensure Docker daemon is installed/running via your distro."
  fi
}

case "$PKG_MANAGER" in
  apt) install_with_apt ;;
  dnf) install_with_dnf ;;
  yum) install_with_yum ;;
  pacman) install_with_pacman ;;
  zypper) install_with_zypper ;;
  brew) install_with_brew ;;
esac

# Post-install checks.
missing=0
for tool in "${REQUIRED_TOOLS[@]}"; do
  if have "$tool"; then
    success "$tool installed"
  else
    warn "$tool missing"
    missing=1
  fi
done

for tool in "${OPTIONAL_TOOLS[@]}"; do
  if have "$tool"; then
    success "$tool installed (optional)"
  else
    warn "$tool missing (optional)"
  fi
done

if have docker; then
  if docker ps >/dev/null 2>&1; then
    success "docker daemon reachable"
  else
    warn "docker installed, but daemon is not reachable for current user"
    warn "Try: sudo systemctl start docker && sudo usermod -aG docker \$USER && newgrp docker"
  fi
fi

if [ "$missing" -ne 0 ]; then
  warn "Some required tools are still missing. Check package availability for your distro."
  exit 2
fi

success "Dependency install/check complete."
