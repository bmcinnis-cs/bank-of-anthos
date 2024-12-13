# Data source to get the latest valid GKE version
data "google_container_engine_versions" "gke_version" {
  location       = "us-central1-c"
  version_prefix = "1.31."
}

resource "google_container_cluster" "boa" {
  name               = "boa"
  location           = "us-central1-c"
  description        = "cluster for tmm-fcs"
  project            = "tmm-fcs-444213"

  networking_mode    = "VPC_NATIVE"
  network            = "projects/tmm-fcs-444213/global/networks/default"
  subnetwork         = "projects/tmm-fcs-444213/regions/us-central1/subnetworks/default"

  # Remove default node pool and create custom one
  remove_default_node_pool = true
  initial_node_count       = 1

  # Use the latest valid version from the "REGULAR" channel
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version

  # Binary authorization (optional, remove if not needed)
  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  # IP allocation policy (required for VPC-native clusters)
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = false
    master_ipv4_cidr_block  = "172.16.0.0/28"  # Required even if private nodes are disabled
  }

  # Release channel
  release_channel {
    channel = "REGULAR"
  }

  # Logging configuration
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Monitoring configuration
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Workload Identity configuration (optional, but recommended)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Create a custom node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  location   = "us-central1-c"
  cluster    = google_container_cluster.tfer--boa.name
  node_count = 1

  # Use the same version as the master
  version    = data.google_container_engine_versions.gke_version.latest_master_version

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = "default"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable Workload Identity on the node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Upgrade settings (optional, but recommended)
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Variable for project ID (add this at the top of your file or in a separate variables.tf file)
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "tmm-fcs-444213"
}
