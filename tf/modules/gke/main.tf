resource "google_container_cluster" "nodeapp" {
  name                     = "nodeapp"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.vpc_name
  subnetwork               = var.private_subnet
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  networking_mode          = "VPC_NATIVE"
  default_max_pods_per_node = 8


  node_locations = data.google_compute_zones.available.names

  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.service_range_name
    
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
}

resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.nodeapp.id
  node_count = 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    labels = {
      role = "general"
    }
  }
}

resource "google_container_node_pool" "spot" {
  name    = "spot"
  cluster = google_container_cluster.nodeapp.id

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    labels = {
      team = "spot"
    }

  }
}
