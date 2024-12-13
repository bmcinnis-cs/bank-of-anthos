# Data source to get the latest valid GKE version
data "google_container_engine_versions" "gke_version" {
  location       = "us-central1-c"
  version_prefix = "1.31."
}

data "google_client_config" "provider" {}

resource "google_container_cluster" "boa" {
  name     = "boa"
  location = "us-central1-c"
  project  = var.project_id

  # Use the latest valid version from the "REGULAR" channel
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version

  # Remove default node pool and create custom one
  remove_default_node_pool = true
  initial_node_count       = 1

  # Networking (minimal required settings)
  networking_mode = "VPC_NATIVE"
  network         = "default"
  subnetwork      = "default"

  # IP allocation policy (required for VPC-native clusters)
  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  location   = "us-central1-c"
  cluster    = google_container_cluster.boa.name
  node_count = 2

  # Use the same version as the master
  version = data.google_container_engine_versions.gke_version.latest_master_version

  node_config {
    machine_type = "e2-standard-2"

    # Use the existing service account
    service_account = "harness-delegate-sa@tmm-fcs-444213.iam.gserviceaccount.com"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Harness Delegate Module
module "delegate" {
  source  = "harness/harness-delegate/kubernetes"
  version = "0.1.8"

  account_id       = "1pqLXHFXQAidtmjjWuAWaQ"
  delegate_token   = var.delegate_token
  delegate_name    = "terraform-delegate"
  deploy_mode      = "KUBERNETES"
  namespace        = "harness-delegate-ng"
  manager_endpoint = "https://app.harness.io"
  delegate_image   = "harness/delegate:24.11.84502"
  replicas         = 1
  upgrader_enabled = true

  depends_on = [google_container_node_pool.primary_nodes]
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = google_container_cluster.boa.endpoint
    token                  = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.boa.master_auth[0].cluster_ca_certificate)
  }
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "tmm-fcs-444213"
}

variable "delegate_token" {
  description = "Harness Delegate Token"
  type        = string
  sensitive   = true
  default     = "NDY3OWFiZGJhZWMwZDhkMjQ0MzE4YmQ0MTkzNzM1M2Y="
}

# Outputs
output "cluster_name" {
  value = google_container_cluster.boa.name
}

output "cluster_location" {
  value = google_container_cluster.boa.location
}

output "kubeconfig" {
  value     = base64encode(templatefile("${path.module}/kubeconfig-template.tpl", {
    cluster_name    = google_container_cluster.boa.name,
    endpoint        = google_container_cluster.boa.endpoint,
    cluster_ca      = google_container_cluster.boa.master_auth[0].cluster_ca_certificate,
    token           = data.google_client_config.provider.access_token,
  }))
  sensitive = true
}
