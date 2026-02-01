/******************************************
	            VPC Network
 *****************************************/
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

/******************************************
	      Subnet Creation for VPC
 *****************************************/
locals {
  subnet_names = {
    for subnet in var.subnetworks :
    subnet.subnet_name => subnet
  }
}

output "debug_subnet_names_local" {
  description = "Debug output for the subnet_names local block"
  value       = local.subnet_names
}

resource "google_compute_subnetwork" "vpc_subnets" {
  for_each = var.subnetworks != null ? local.subnet_names : {}

  name          = each.value.subnet_name
  ip_cidr_range = each.value.ip_cidr
  region        = each.value.region
  network       = var.network_name
  project       = var.project_id

  # Enables private access to Google APIs (Standard Best Practice)
  private_ip_google_access = lookup(each.value, "subnet_private_access", false)

  # Dynamic block for GKE pods and services
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges != null ? each.value.secondary_ranges : {}
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  description = lookup(each.value, "description", null)
}
