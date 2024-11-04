# The VPC configuration, three private subnets and one public for the bastion host

resource "google_compute_network" "gcp-vpc" {
  name = "mongodb-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = true 
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = false
}

# NAT Gateway 

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.gcp-vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

#Bastion Host

resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = var.machine_type 
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.gcp-vpc.name
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config { 

    }
  }
    tags = ["allow-ssh-http"] 
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "allow-ssh-http"
  network = google_compute_network.gcp-vpc.name  

  allow {
    protocol = "tcp"
    ports    = ["22", "80"] 
  }

  source_ranges = ["0.0.0.0/0"]  

  target_tags = ["allow-ssh-http"] 
}
