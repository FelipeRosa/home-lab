resource "kubernetes_config_map" "grafana_config" {
  metadata {
    name = "grafana-config"
  }
  data = {
    "grafana.ini" = file("./grafana-config/grafana.ini")
  }
}

resource "kubernetes_stateful_set" "grafana" {
  metadata {
    name = "grafana"
  }

  spec {
    selector {
      match_labels = {
        app = "grafana"
      }
    }

    service_name = "grafana"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:9.3.0"

          resources {
            limits = {
              cpu    = "75m"
              memory = "128Mi"
            }
          }

          port {
            container_port = 3000
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/grafana"
          }
          volume_mount {
            name       = "config-file"
            mount_path = "/etc/grafana/grafana.ini"
            sub_path   = "grafana.ini"
          }
        }

        volume {
          name = "config-file"
          config_map {
            name = kubernetes_config_map.grafana_config.metadata[0].name
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

resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 3000
    }
  }
}
