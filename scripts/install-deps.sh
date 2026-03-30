#!/usr/bin/env bash
set -euo pipefail

# Portable dependency installer for this repository.
# Supports: apt, dnf, yum, pacman, zypper, brew
#
# Optional env vars:
#   DRY_RUN=1                Print commands instead of executing
#   PKG_MANAGER_OVERRIDE=apt Force a package manager branch

REQUIRED_TOOLS=(git curl node npm docker terraform kubectl helm)
OPTIONAL_TOOLS=(minikube)
MINIKUBE_INSTALL_URL="https://minikube.sigs.k8s.io/docs/start/"

info() { printf '[INFO] %s\n' "$*"; }
success() { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
error() { printf '[ERR]  %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '[DRY]  %s\n' "$*"
    return 0
  fi
  eval "$*"
}

SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  if have sudo; then
    SUDO="sudo"
  else
    error "This script needs root privileges for package installs (sudo not found)."
    exit 1
  fi
fi

PKG_MANAGER="${PKG_MANAGER_OVERRIDE:-}"
if [ -z "$PKG_MANAGER" ]; then
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
fi

info "Detected package manager: ${PKG_MANAGER}"

sanitize_apt_repos() {
  # Handle common failure: stale HashiCorp apt repo on unsupported distro (e.g. kali-rolling).
  if [ "$PKG_MANAGER" != "apt" ]; then return 0; fi
  local codename
  codename="$(lsb_release -cs 2>/dev/null || true)"
  if [ -f /etc/apt/sources.list.d/hashicorp.list ]; then
    case "$codename" in
      kali-rolling|kali*|rolling)
        warn "Removing unsupported HashiCorp apt repo for '${codename}'"
        run "${SUDO:+$SUDO }rm -f /etc/apt/sources.list.d/hashicorp.list" || true
        ;;
    esac
  fi
}

install_helm_fallback() {
  if have helm; then return 0; fi
  warn "Installing Helm via official install script fallback..."
  run "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | ${SUDO:+$SUDO }bash" || true
}

install_terraform_fallback() {
  if have terraform; then return 0; fi

  # Try HashiCorp apt repo only for Debian/Ubuntu codename that repo supports.
  if [ "$PKG_MANAGER" = "apt" ] && have lsb_release; then
    local codename
    codename="$(lsb_release -cs 2>/dev/null || true)"
    case "$codename" in
      bookworm|bullseye|jammy|focal|noble)
        warn "Attempting Terraform install via HashiCorp apt repo for '${codename}'"
        run "curl -fsSL https://apt.releases.hashicorp.com/gpg | ${SUDO:+$SUDO }gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg" || true
        run "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${codename} main' | ${SUDO:+$SUDO }tee /etc/apt/sources.list.d/hashicorp.list >/dev/null" || true
        run "${SUDO:+$SUDO }apt-get update" || true
        run "${SUDO:+$SUDO }apt-get install -y terraform" || true
        ;;
      *)
        warn "Skipping HashiCorp apt repo for unsupported distro codename '${codename}'"
        ;;
    esac
  fi

  if have terraform; then return 0; fi

  warn "Installing Terraform via official zip fallback..."
  local arch tfv url
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      warn "Unsupported architecture '${arch}' for Terraform auto-install"
      return 0
      ;;
  esac

  tfv="$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/terraform | grep -oE '"version":"[0-9]+\.[0-9]+\.[0-9]+"' | head -1 | cut -d '"' -f4 || true)"
  if [ -z "$tfv" ]; then
    warn "Could not detect latest Terraform version from API"
    return 0
  fi

  url="https://releases.hashicorp.com/terraform/${tfv}/terraform_${tfv}_linux_${arch}.zip"
  run "curl -fsSLo /tmp/terraform.zip '${url}'" || true
  run "${SUDO:+$SUDO }mkdir -p /usr/local/bin" || true
  run "${SUDO:+$SUDO }unzip -o /tmp/terraform.zip -d /usr/local/bin" || true
}

install_kubectl_fallback() {
  if have kubectl; then return 0; fi
  if [ "$PKG_MANAGER" != "apt" ]; then return 0; fi

  warn "Installing kubectl via Kubernetes apt repo fallback..."
  run "${SUDO:+$SUDO }mkdir -p /etc/apt/keyrings" || true
  run "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | ${SUDO:+$SUDO }gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg" || true
  run "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | ${SUDO:+$SUDO }tee /etc/apt/sources.list.d/kubernetes.list >/dev/null" || true
  run "${SUDO:+$SUDO }apt-get update" || true
  run "${SUDO:+$SUDO }apt-get install -y kubectl" || true
}

install_with_apt() {
  sanitize_apt_repos
  run "${SUDO:+$SUDO }apt-get update" || true

  # Install package-by-package so one missing package doesn't abort the rest.
  local pkgs=(git curl ca-certificates gnupg lsb-release nodejs npm docker.io docker-compose kubectl unzip)
  for p in "${pkgs[@]}"; do
    run "${SUDO:+$SUDO }apt-get install -y ${p}" || warn "apt package not available: ${p}"
  done
  install_kubectl_fallback

  # Prefer apt helm if available; fallback otherwise.
  run "${SUDO:+$SUDO }apt-get install -y helm" || true
  install_helm_fallback

  # Try apt terraform, then fallbacks.
  run "${SUDO:+$SUDO }apt-get install -y terraform" || true
  install_terraform_fallback

  # Optional tool.
  run "${SUDO:+$SUDO }apt-get install -y minikube" || true

  if have systemctl; then
    run "${SUDO:+$SUDO }systemctl enable --now docker" || true
  fi
}

install_with_dnf() {
  run "${SUDO:+$SUDO }dnf -y install git curl nodejs npm docker kubernetes-client helm terraform" || true
  run "${SUDO:+$SUDO }dnf -y install minikube" || true
  run "${SUDO:+$SUDO }systemctl enable --now docker" || true
}

install_with_yum() {
  run "${SUDO:+$SUDO }yum -y install git curl nodejs npm docker kubectl helm terraform" || true
  run "${SUDO:+$SUDO }yum -y install minikube" || true
  run "${SUDO:+$SUDO }systemctl enable --now docker" || true
}

install_with_pacman() {
  run "${SUDO:+$SUDO }pacman -Sy --noconfirm git curl nodejs npm docker docker-compose terraform kubectl helm minikube" || true
  run "${SUDO:+$SUDO }systemctl enable --now docker" || true
}

install_with_zypper() {
  run "${SUDO:+$SUDO }zypper --non-interactive install git curl nodejs npm docker terraform kubectl helm minikube" || true
  run "${SUDO:+$SUDO }systemctl enable --now docker" || true
}

install_with_brew() {
  run "brew update"
  run "brew install git curl node terraform kubectl helm minikube docker docker-compose" || true
  if [ "$(uname -s)" = "Darwin" ]; then
    run "brew install --cask docker" || true
    warn "If Docker commands fail, open Docker Desktop once to start the daemon."
  else
    warn "On Linux, brew docker is often CLI only. Ensure daemon is installed/running via distro packages."
  fi
}

case "$PKG_MANAGER" in
  apt) install_with_apt ;;
  dnf) install_with_dnf ;;
  yum) install_with_yum ;;
  pacman) install_with_pacman ;;
  zypper) install_with_zypper ;;
  brew) install_with_brew ;;
  *) error "Unsupported package manager override: $PKG_MANAGER"; exit 1 ;;
esac

missing=0
missing_optional=()
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
    missing_optional+=("$tool")
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

# In dry-run mode we only validate flow/commands, not actual installation state.
if [ "${DRY_RUN:-0}" = "1" ]; then
  success "Dry-run completed."
  exit 0
fi

for tool in "${missing_optional[@]}"; do
  case "$tool" in
    minikube)
      info "To install optional tool '${tool}', see the official guide: ${MINIKUBE_INSTALL_URL}"
      ;;
  esac
done

if [ "$missing" -ne 0 ]; then
  warn "Some required tools are still missing. Check package availability for your distro."
  exit 2
fi

success "Dependency install/check complete."
