resource "google_container_cluster" "nodeapp" {
  name                     = "nodeapp"
  location                 = data.google_compute_zones[0].available.names
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.vpc_name
  subnetwork               = var.private_subnet
  logging_service          = "logging.googleapis.com/kubernetes"
  networking_mode          = "VPC_NATIVE"
  default_max_pods_per_node = 30


  node_locations = data.google_compute_zones[1].available.names

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

  metadata = {
      ssh-keys = "USERNAME:${file("/home/keretdodor/Desktop/gcp-project/gke-key.pub")}"
    }
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    tags = ["gke-nodes"]  
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

  metadata = {
    ssh-keys = "USERNAME:${file("/home/keretdodor/Desktop/gcp-project/gke-key.pub")}"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    tags = ["gke-nodes"]  
    preemptible  = true
    machine_type = "e2-medium"

    labels = {
      team = "spot"
    }

  }
}



resource "google_compute_firewall" "bastion_ssh_firewall" {
  name    = "bastion-ssh-access"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.bastion_prv_ip]
  target_tags   = ["gke-nodes"] 
}


