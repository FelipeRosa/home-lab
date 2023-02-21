resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name = "prometheus-config"
  }
  data = {
    "prometheus.yml" = file("./prometheus-config/prometheus.yml")
  }
}

resource "kubernetes_stateful_set" "prometheus" {
  metadata {
    name = "prometheus"
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
            name       = "data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "config-file"
            mount_path = "/etc/prometheus/prometheus.yml"
            sub_path   = "prometheus.yml"
          }
        }

        volume {
          name = "config-file"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
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

resource "kubernetes_service" "prometheus" {
  metadata {
    name = "prometheus"
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      protocol    = "TCP"
      port        = 9090
      target_port = 9090
    }
  }
}
