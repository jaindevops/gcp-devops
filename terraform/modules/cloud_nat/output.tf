output "router_names" {
  description = "The names of the routers created in the VPC network"
  value       = [for router in google_compute_router.vpc_router : router.name]
}

output "router_details" {
  description = "The detailed list of routers created in the VPC network"
  value = [
    for router in google_compute_router.vpc_router :
    {
      name    = router.name
      region  = router.region
      network = router.network
    }
  ]
}

output "nat_names" {
  description = "The names of the Cloud NAT gateways created"
  value       = [for nat in google_compute_router_nat.cloud_nat : nat.name]
}

output "nat_details" {
  description = "The detailed list of Cloud NAT gateways created"
  value = [
    for nat in google_compute_router_nat.cloud_nat :
    {
      name                               = nat.name
      router                             = nat.router
      region                             = nat.region
      nat_ip_allocate_option             = nat.nat_ip_allocate_option
      source_subnetwork_ip_ranges_to_nat = nat.source_subnetwork_ip_ranges_to_nat
      enable_dynamic_port_allocation     = nat.enable_dynamic_port_allocation
      nat_ips                            = nat.nat_ips
    }
  ]
}