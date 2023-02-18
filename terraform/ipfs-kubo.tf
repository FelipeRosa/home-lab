resource "kubernetes_stateful_set" "ipfs_kubo" {
  metadata {
    name = "ipfs-kubo"
  }

  spec {
    selector {
      match_labels = {
        app = "ipfs-kubo"
      }
    }

    service_name = "ipfs-kubo"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "ipfs-kubo"
        }
      }

      spec {
        container {
          name  = "ipfs-kubo"
          image = "ipfs/kubo:v0.18.1"

          resources {
            limits = {
              cpu    = "125m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data/ipfs"
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
            storage = "20Gi"
          }
        }
      }
    }
  }
}
