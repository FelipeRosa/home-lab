resource "kubernetes_config_map" "cardano-node-config" {
  metadata {
    name = "cardano-node-config"
  }

  data = {
    for f in fileset("./cardano-node-config", "*.json") :
    f => file(join("/", ["cardano-node-config", f]))
  }
}

resource "kubernetes_stateful_set" "cardano-node" {
  depends_on = [
    kubernetes_config_map.cardano-node-config
  ]

  metadata {
    name = "cardano-node"
  }

  spec {
    selector {
      match_labels = {
        app = "cardano-node"
      }
    }

    service_name = "cardano-node"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "cardano-node"
        }
      }

      spec {
        container {
          name  = "cardano-node"
          image = "inputoutput/cardano-node:1.35.3"
          command = [
            "cardano-node",
            "run",
            "--config",
            "/config/config.json",
            "--topology",
            "/config/topology.json",
            "--database-path",
            "/data/cardano-node-db",
            "--socket-path",
            "/data/node.socket",
          ]

          resources {
            limits = {
              cpu    = "2000m"
              memory = "2Gi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.cardano-node-config.metadata[0].name
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
            storage = "80Gi"
          }
        }
      }
    }
  }
}
