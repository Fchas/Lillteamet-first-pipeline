# redis.tf — Redis deployment and service

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace

    labels = {
      app         = "redis"
      managed-by  = "terraform"
      team        = var.team_name
      environment = var.environment
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = var.redis_image

          port {
            container_port = 6379
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}
