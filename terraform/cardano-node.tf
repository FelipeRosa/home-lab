resource "kubernetes_config_map" "cardano_node_config" {
  metadata {
    name = "cardano-node-config"
  }

  data = {
    for f in fileset("./cardano-node-config", "*.json") :
    f => file(join("/", ["cardano-node-config", f]))
  }
}

resource "kubernetes_stateful_set" "cardano_node" {
  depends_on = [
    kubernetes_config_map.cardano_node_config
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
          image = "inputoutput/cardano-node:1.35.5"
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

          env {
            name  = "CARDANO_NODE_SOCKET_PATH"
            value = "/data/node.socket"
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          port {
            name           = "metrics"
            protocol       = "TCP"
            container_port = 12798
          }
        }

        container {
          name  = "cardano-wallet"
          image = "inputoutput/cardano-wallet:2022.12.14"
          args = [
            "serve",
            "--listen-address",
            "0.0.0.0",
            "--node-socket",
            "/data/node.socket",
            "--testnet",
            "/config/byron-genesis.json",
            "--database",
            "/data/wallet-database"
          ]

          resources {
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
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

          port {
            name           = "api"
            container_port = 8090
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.cardano_node_config.metadata[0].name
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

resource "kubernetes_service" "cardano_node" {
  metadata {
    name = "cardano-node"
  }

  spec {
    selector = {
      app = "cardano-node"
    }

    port {
      name        = "metrics"
      protocol    = "TCP"
      port        = 12798
      target_port = "metrics"
    }

    port {
      name        = "api"
      protocol    = "TCP"
      port        = 8090
      target_port = "api"
    }
  }
}
