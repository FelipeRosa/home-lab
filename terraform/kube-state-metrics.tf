resource "kubernetes_cluster_role" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extesions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_service_account" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }
}

resource "kubernetes_secret_v1" "kube_state_metrics_service_account_token" {
  metadata {
    name = "kube-state-metrics-service-account-token"
    annotations = {
      "kubernetes.io/service-account.name" = "kube-state-metrics"
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kube-state-metrics"
  }

  subject {
    kind = "ServiceAccount"
    name = "kube-state-metrics"
  }
}


resource "kubernetes_deployment_v1" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  spec {
    selector {
      match_labels = {
        app = "kube-state-metrics"
      }
    }

    template {
      metadata {
        labels = {
          app = "kube-state-metrics"
        }
      }

      spec {
        service_account_name = "kube-state-metrics"

        container {
          name  = "kube-state-metrics"
          image = "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.7.0"

          resources {
            limits = {
              cpu    = "75m"
              memory = "128Mi"
            }
          }

          port {
            name           = "metrics"
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  spec {
    selector = {
      app = "kube-state-metrics"
    }

    port {
      name        = "metrics"
      port        = 8080
      target_port = "metrics"
    }
  }
}
