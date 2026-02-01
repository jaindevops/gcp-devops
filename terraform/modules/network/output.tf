output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_names" {
  description = "The names of the subnetworks created in the VPC network"
  value       = [for subnet in google_compute_subnetwork.vpc_subnets : subnet.name]
}

output "subnetworks" {
  value       = google_compute_subnetwork.vpc_subnets
  description = "The subnetworks created in the VPC network"
}
