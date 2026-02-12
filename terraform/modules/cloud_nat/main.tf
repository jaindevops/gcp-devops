resource "google_compute_router" "vpc_router" {
  for_each = { for router in var.vpc_router : router.name => router }

  name    = each.value.name
  network = each.value.network_name
  region  = each.value.region
  project = var.project_id
}


locals {
  # Create a flat map of all IP addresses needed across all MANUAL_ONLY NATs.
  # The key for each IP address will be "${nat_name}-${ip_name}".
  ip_details = {
    for ip_details in flatten([
      for nat_config in var.cloud_nat :
      [
        for ip_name in nat_config.nat_ips :
        {
          nat_name = nat_config.nat_name
          region   = nat_config.region
          ip_name  = ip_name
        }
      ] if nat_config.nat_ip_allocate_option == "MANUAL_ONLY" && length(nat_config.nat_ips) > 0
    ]) : "${ip_details.nat_name}-${ip_details.ip_name}" => ip_details
  }
}


# This resource creates external IP addresses for Cloud NAT gateways
# that are configured with MANUAL_ONLY allocation and have nat_ips specified.
resource "google_compute_address" "cloud_nat_ip" {
  for_each = local.ip_details

  name    = each.value.ip_name
  region  = each.value.region
  project = var.project_id
}

resource "google_compute_router_nat" "cloud_nat" {
  for_each                           = { for nat in var.cloud_nat : nat.nat_name => nat }
  name                               = each.value.nat_name
  router                             = each.value.router_name
  region                             = each.value.region # Use the region from the cloud_nat object
  project                            = var.project_id
  min_ports_per_vm                   = each.value.min_ports_per_vm
  max_ports_per_vm                   = each.value.enable_dynamic_port_allocation ? each.value.max_ports_per_vm : null
  nat_ip_allocate_option             = each.value.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat
  enable_dynamic_port_allocation     = each.value.enable_dynamic_port_allocation

  # If MANUAL_ONLY, collect the self_links of the IPs created for this specific NAT gateway.
  # Otherwise, provide an empty list (AUTO_ONLY handles IP allocation internally).
  nat_ips = each.value.nat_ip_allocate_option == "MANUAL_ONLY" && length(each.value.nat_ips) > 0 ? [
    for ip_name in each.value.nat_ips :
    google_compute_address.cloud_nat_ip["${each.value.nat_name}-${ip_name}"].self_link
  ] : []

  dynamic "subnetwork" {
    for_each = each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? each.value.subnetwork_ip_ranges_to_nat_list : []
    content {
      name                     = subnetwork.value.subnetwork_name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = subnetwork.value.secondary_ip_range_names
    }
  }

  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      enable = each.value.enable_logging
      filter = each.value.log_filter
    }
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_router.vpc_router
  ]
}