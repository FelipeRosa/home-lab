resource "kubernetes_service_account" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_secret_v1" "prometheus_service_account_token" {
  metadata {
    name = "prometheus-service-account-token"
    annotations = {
      "kubernetes.io/service-account.name" = "prometheus"
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "ServiceAccount"
    name = "prometheus"
  }
}


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
        service_account_name = "prometheus"

        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.42.0"
          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--log.level=debug"
          ]

          resources {
            limits = {
              cpu    = "125m"
              memory = "512Mi"
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
