output "vpc_name" {
  value = google_compute_network.gcp-vpc.name
  description = "The table's name"
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private_subnet.name
  description = "The table's name"
}

output "bastion_host" {
  value = google_compute_instance.bastion_host.network_interface[0].network_ip
  description = "The table's name"
}

