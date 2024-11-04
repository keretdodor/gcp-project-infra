output "vpc_name" {
  value = google_compute_network.gcp-vpc.name
  description = "The table's name"
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private_subnet.name
  description = "The table's name"
}

output "bastion_host" {
  value = network_interface.0.access_config.0.nat_ip
  description = "The table's name"
}

