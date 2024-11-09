###################################################################################
# The VPC configuration, two private subnets and one public for the bastion host
###################################################################################

resource "google_compute_network" "gcp-vpc" {
  name = "mongodb-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mongo_prv_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = true 
}
resource "google_compute_subnetwork" "k8s_prv_sub" {
  name                     = "k8s-prv-sub"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.gcp-vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.0.2.0/25"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range" 
    ip_cidr_range = "10.0.2.128/25"
  }
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.gcp-vpc.id
  private_ip_google_access = false
}

###########################################################################
#                               NAT Gateway 
###########################################################################

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.gcp-vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat_gateway" {
  name                   = "nat-gateway"
  router                 = google_compute_router.nat_router.name
  region                 = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.mongo_prv_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.k8s_prv_sub.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  
  nat_ips = [google_compute_address.nat.self_link]

}

resource "google_compute_address" "nat" {
  name         = "nat"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

}

###########################################################################
#                               Bastion Host 
###########################################################################

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
   metadata = {
    ssh-keys = "keretdodorc:${file("/home/keretdodor/Desktop/gcp-project/bastion_host.pub")}"
   }
   
    provisioner "file" {
    source      = "/home/keretdodor/Desktop/gcp-project/mongo_key.pem"  
    destination = "/home/keretdodorc/mongo_key.pem"      
    connection {
      type        = "ssh"
      user        = "keretdodorc"
      private_key = file("/home/keretdodor/Desktop/gcp-project/bastion_host.pem")
      host        = self.network_interface[0].access_config[0].nat_ip
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

###########################################################################
#                               Demo nodeapp
###########################################################################
 
data "archive_file" "example" {
  type        = "zip"
  source_dir  = "/home/keretdodor/Desktop/gcp-project/node"  
  output_path = "./node.zip"
}

resource "google_compute_instance" "node_host" {
  name         = "node-host"
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
   metadata = {
    ssh-keys = "keretdodorc:${file("/home/keretdodor/Desktop/gcp-project/bastion_host.pub")}"
   }

    tags = ["allow-ssh-http"] 
}
 