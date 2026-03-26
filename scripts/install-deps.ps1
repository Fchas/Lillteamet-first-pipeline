param(
  [switch]$SkipOptional
)

$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Err($msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

function Have-Cmd($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-Admin {
  $current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  $isAdmin = $current.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  if (-not $isAdmin) {
    Err "Run this script in an elevated PowerShell (Run as Administrator)."
    exit 1
  }
}

function Install-WithWinget {
  param([string]$Id)
  try {
    winget install --id $Id --accept-source-agreements --accept-package-agreements --silent | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Install-WithChoco {
  param([string]$Pkg)
  try {
    choco install $Pkg -y --no-progress | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Ensure-Choco {
  if (Have-Cmd choco) { return }
  Info "Chocolatey not found. Installing Chocolatey..."
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Ensure-Admin

$hasWinget = Have-Cmd winget
$hasChoco = Have-Cmd choco

if (-not $hasWinget -and -not $hasChoco) {
  Warn "Neither winget nor choco found. Attempting to install Chocolatey."
  Ensure-Choco
  $hasChoco = Have-Cmd choco
}

if (-not $hasWinget -and -not $hasChoco) {
  Err "No supported package manager found (winget/choco)."
  exit 1
}

Info "Using package manager priority: winget -> choco"

# Required tools mapping
$required = @(
  @{ Name = 'Git'; Cmd = 'git'; Winget = 'Git.Git'; Choco = 'git' },
  @{ Name = 'Node.js LTS'; Cmd = 'node'; Winget = 'OpenJS.NodeJS.LTS'; Choco = 'nodejs-lts' },
  @{ Name = 'Docker Desktop'; Cmd = 'docker'; Winget = 'Docker.DockerDesktop'; Choco = 'docker-desktop' },
  @{ Name = 'Terraform'; Cmd = 'terraform'; Winget = 'Hashicorp.Terraform'; Choco = 'terraform' },
  @{ Name = 'kubectl'; Cmd = 'kubectl'; Winget = 'Kubernetes.kubectl'; Choco = 'kubernetes-cli' },
  @{ Name = 'Helm'; Cmd = 'helm'; Winget = 'Helm.Helm'; Choco = 'kubernetes-helm' }
)

$optional = @(
  @{ Name = 'Minikube'; Cmd = 'minikube'; Winget = 'Kubernetes.minikube'; Choco = 'minikube' }
)

function Install-Tool($tool) {
  if (Have-Cmd $tool.Cmd) {
    Ok "$($tool.Name) already installed"
    return
  }

  Info "Installing $($tool.Name)..."
  $installed = $false

  if ($hasWinget) {
    $installed = Install-WithWinget -Id $tool.Winget
  }

  if (-not $installed) {
    if (-not (Have-Cmd choco)) {
      Ensure-Choco
    }
    if (Have-Cmd choco) {
      $installed = Install-WithChoco -Pkg $tool.Choco
    }
  }

  if ($installed) {
    Ok "$($tool.Name) installation command completed"
  } else {
    Warn "Could not auto-install $($tool.Name). Install manually if needed."
  }
}

foreach ($tool in $required) { Install-Tool $tool }
if (-not $SkipOptional) {
  foreach ($tool in $optional) { Install-Tool $tool }
}

Write-Host ""
Info "Post-install verification:"
$missingRequired = @()
foreach ($tool in $required) {
  if (Have-Cmd $tool.Cmd) {
    Ok "$($tool.Cmd) available"
  } else {
    Warn "$($tool.Cmd) missing"
    $missingRequired += $tool.Cmd
  }
}

if (-not $SkipOptional) {
  foreach ($tool in $optional) {
    if (Have-Cmd $tool.Cmd) {
      Ok "$($tool.Cmd) available (optional)"
    } else {
      Warn "$($tool.Cmd) missing (optional)"
    }
  }
}

if (Have-Cmd docker) {
  try {
    docker version | Out-Null
    Ok "Docker CLI reachable"
  } catch {
    Warn "Docker installed but daemon may not be running. Start Docker Desktop and retry."
  }
}

if ($missingRequired.Count -gt 0) {
  Warn "Missing required tools: $($missingRequired -join ', ')"
  Warn "Open a new PowerShell after install; PATH updates may require a new session."
  exit 2
}

Ok "All required tools installed or available."
