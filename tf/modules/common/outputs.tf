output "vpc_name" {
  value = google_compute_network.gcp-vpc.name
  description = "The table's name"
}

output "private_subnet_name" {
  value = google_compute_subnetwork.mongo_prv_subnet.name
  description = "The table's name"
}

output "private_subnet_name" {
  value = google_compute_subnetwork.k8s_prv_sub.name
  description = "The table's name"
}

output "bastion_prv_ip" {
  value = google_compute_instance.bastion_host.network_interface[0].network_ip
  description = "The table's name"
}

output "bastion_pub_ip" {
  value = google_compute_instance.bastion_host.network_interface[0].access_config[0].nat_ip
  description = "The table's name"
}

output "nat_router_id" {
  value = google_compute_router.nat_router.id
}
