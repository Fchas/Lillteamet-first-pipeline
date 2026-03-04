resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api"
    namespace = var.namespace

    labels = {
      app         = "api"
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    replicas = var.api_replicas

    selector {
      match_labels = {
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app         = "api"
          environment = var.environment
        }
      }

      spec {
        container {
          name  = "api"
          image = var.api_image

          port {
            container_port = 3000
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}
