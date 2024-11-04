# The VPC configuration, three private subnets and one public for the bastion host


resource "google_compute_network" "gcp-vpc" {
  name = "mongodb-vpc"
}

resource "google_compute_subnetwork" "private_subnet" {
  count         = 3
  name          = "private-subnet-${count.index}"
  ip_cidr_range = "10.0.${count.index}.0/24"
  region        = "us-central1"
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = true 
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = "us-central1"
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = false
}

# NAT Gateway 

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.gcp-vpc.name
  region  = "us-central1"
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

#Bastion Host

resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = var.machine_type 
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.gcp.vpc.name
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config { 
      nat_ip = google_compute_address.bastion_ip.address
    }
  }
}