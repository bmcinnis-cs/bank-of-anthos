# Data source to get the latest valid GKE version
data "google_container_engine_versions" "gke_version" {
  location       = "us-central1-c"
  version_prefix = "1.31."
}

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

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "tmm-fcs-444213"
}
