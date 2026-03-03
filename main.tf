# main.tf — Terraform config for your team namespace

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# Use your existing kubeconfig — the same one from Week 6
provider "kubernetes" {
  config_path = "~/.kube/config"
  # Or if you use KUBECONFIG env var, Terraform picks it up automatically
}

# Ensure target namespace exists
resource "kubernetes_namespace" "team" {
  metadata {
    name = "lillteamet"
  }
}

# Create a ConfigMap in your team namespace
resource "kubernetes_config_map" "app_config" {
  depends_on = [kubernetes_namespace.team]

  metadata {
    name      = "terraform-demo"
    namespace = "lillteamet"  # Replace: girly-pops, m4k-gang, etc.

    labels = {
      "managed-by" = "terraform"
      "team"       = "lillteamet"
    }
  }

  data = {
    APP_ENV     = "production"
    APP_VERSION = "2.0.0"
    MANAGED_BY  = "terraform"
  }
}
