terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "team" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_config_map" "app_config" {
  depends_on = [kubernetes_namespace.team]

  metadata {
    name      = "terraform-demo"
    namespace = var.namespace

    labels = {
      "managed-by" = "terraform"
      "team"       = var.namespace
    }
  }

  data = {
    APP_ENV     = "production"
    APP_VERSION = "2.0.0"
    MANAGED_BY  = "terraform"
  }
}
