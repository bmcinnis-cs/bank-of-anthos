resource "google_container_cluster" "tfer--bc-1" {
  name               = "bc-1"
  location           = "us-central1-c"
  description        = "cluster for tmm-fcs"
  project            = "tmm-fcs-444213"

  enable_autopilot   = false
  networking_mode    = "VPC_NATIVE"
  network            = "projects/tmm-fcs-444213/global/networks/default"
  subnetwork         = "projects/tmm-fcs-444213/regions/us-central1/subnetworks/default"

  initial_node_count = 0

  addons_config {
    dns_cache_config {
      enabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = true
    }
  }

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  cluster_autoscaling {
    enabled = false
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

  node_version = "1.30.5-gke.1699000"

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["CADVISOR", "DAEMONSET", "DEPLOYMENT", "HPA", "KUBELET", "POD", "STATEFULSET", "STORAGE", "SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Remove network_policy block as it's disabled in addons_config

  # Other configurations remain the same...
}
