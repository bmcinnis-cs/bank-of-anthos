# ... (previous GKE cluster and node pool configuration remains the same)

resource "kubernetes_namespace" "harness_delegate" {
  metadata {
    name = "harness-delegate-ng"
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

resource "kubernetes_secret" "delegate_token" {
  metadata {
    name      = "harness-delegate-token"
    namespace = kubernetes_namespace.harness_delegate.metadata[0].name
  }

  data = {
    "DELEGATE_TOKEN" = var.delegate_token
  }
}

resource "kubernetes_deployment" "harness_delegate" {
  metadata {
    name      = "harness-delegate"
    namespace = kubernetes_namespace.harness_delegate.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "harness-delegate"
      }
    }

    template {
      metadata {
        labels = {
          app = "harness-delegate"
        }
      }

      spec {
        container {
          image = "harness/delegate:24.11.84502"
          name  = "harness-delegate"

          env {
            name = "ACCOUNT_ID"
            value = "1pqLXHFXQAidtmjjWuAWaQ"
          }

          env {
            name = "DELEGATE_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.delegate_token.metadata[0].name
                key  = "DELEGATE_TOKEN"
              }
            }
          }

          env {
            name  = "DELEGATE_NAME"
            value = "terraform-delegate"
          }

          env {
            name  = "MANAGER_HOST_AND_PORT"
            value = "https://app.harness.io"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.delegate_token]
}

variable "delegate_token" {
  description = "Harness Delegate Token"
  type        = string
  sensitive   = true
  default = "NDY3OWFiZGJhZWMwZDhkMjQ0MzE4YmQ0MTkzNzM1M2Y="
}

# ... (rest of your configuration, including outputs)
