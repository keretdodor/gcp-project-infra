resource "google_compute_firewall" "combined_firewall" {
  name    = "combined-firewall"
  network = google_compute_network.gcp-vpc.name

  // Allow MongoDB internal traffic
  allow {
    protocol = "tcp"
    ports    = ["27017"]
    source_ranges = ["10.0.0.0/16"]
  }

  // Allow SSH access to Bastion Host
  allow {
    protocol = "tcp"
    ports    = ["22"]
    source_ranges = ["<YOUR_TRUSTED_IP>"]
  }

  source_ranges = ["10.0.0.0/16", "<YOUR_TRUSTED_IP>"] // Combine your source ranges as needed
  target_tags   = ["mongodb", "bastion"] // Adjust target tags as necessary
}


resource "google_compute_instance" "mongodb_instances" {
  count        = 3
  name         = "mongodb-${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"
  machine_type = var.instance_type

  