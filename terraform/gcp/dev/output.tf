# output "debug_module_subnet_names" {
#   description = "Debug output for the subnet_names local block from the network module"
#   value       = module.vpc_network.debug_subnet_names_local
# }

output "network_name" {
  description = "The name of the VPC network"
  value       = module.vpc_network.network_name
}

output "subnet_names" {
  description = "The names of the subnetworks created in the VPC network"
  value       = module.vpc_subnetwork.subnet_names
}

output "global_ip_addresses" {
  description = "A map of global IP names to their assigned IP addresses."
  value       = module.static_ips.global_ip_addresses
}