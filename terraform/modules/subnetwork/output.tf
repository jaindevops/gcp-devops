output "subnet_names" {
  description = "The names of the subnetworks created in the VPC network"
  value       = [for subnet in google_compute_subnetwork.vpc_subnets : subnet.name]
}

output "subnetworks" {
  value       = google_compute_subnetwork.vpc_subnets
  description = "The subnetworks created in the VPC network"
}

output "subnet_names_local" {
  description = "Debug output for the subnet_names local block"
  value       = local.subnet_names
}

# output "subnetworks" {
#   description = "The list of subnetworks created in the VPC network"
#   value = [
#     for subnet in google_compute_subnetwork.vpc_subnets :
#     {
#       name    = subnet.name
#       region  = subnet.region
#       ip_cidr = subnet.ip_cidr_range
#       secondary_ip_ranges = subnet.secondary_ip_range != null ? [
#         for range in subnet.secondary_ip_range :
#         {
#           range_name    = range.range_name
#           ip_cidr_range = range.ip_cidr_range
#         }
#       ] : []
#     }
#   ]
# }