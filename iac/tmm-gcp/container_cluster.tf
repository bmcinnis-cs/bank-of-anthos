# Generate a random 4-character suffix
resource "random_string" "cluster_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_container_cluster" "tfer--bc-1" {
  name               = "bc-1-${random_string.cluster_suffix.result}"
  location           = "us-central1-c"
  description        = "cluster for tmm-fcs"
  project            = "tmm-fcs-444213"

  # Remove the enable_autopilot setting
  # enable_autopilot   = false

  networking_mode    = "VPC_NATIVE"
  network            = "projects/tmm-fcs-444213/global/networks/default"
  subnetwork         = "projects/tmm-fcs-444213/regions/us-central1/subnetworks/default"

  # Remove default node pool and create custom one
  remove_default_node_pool = true
  initial_node_count       = 1

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.68.0.0/14"
    services_ipv4_cidr_block = "34.118.224.0/20"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = false
    master_global_access_config {
      enabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  min_master_version = "1.30.5-gke.1699000"

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["CADVISOR", "DAEMONSET", "DEPLOYMENT", "HPA", "KUBELET", "POD", "STATEFULSET", "STORAGE", "SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }
}

# Create a custom node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool-${random_string.cluster_suffix.result}"
  location   = "us-central1-c"
  cluster    = google_container_cluster.tfer--bc-1.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = "default"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
