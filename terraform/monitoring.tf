resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_stateful_set" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "monitoring"
  }

  spec {
    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    service_name = "prometheus"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.42.0"

          resources {
            limits = {
              cpu    = "75m"
              memory = "128Mi"
            }
          }

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "storage"
            mount_path = "/storage"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "10Gi"
          }
        }
      }
    }
  }
}
