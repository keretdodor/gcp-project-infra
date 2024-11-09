output "vpc_name" {
  value = google_compute_network.gcp-vpc.name
  description = "The table's name"
}

output "mongo_prv_sub" {
  value = google_compute_subnetwork.mongo_prv_subnet.name
  description = "The table's name"
}

output "k8s_prv_sub" {
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

output "pod_range_name" {
  value = google_compute_subnetwork.k8s_prv_sub.secondary_ip_range[0].range_name
}

output "service_range_name" {
  value = google_compute_subnetwork.k8s_prv_sub.secondary_ip_range[1].range_name
}