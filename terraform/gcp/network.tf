module "vpc_network" {
  source       = "../modules/network"
  network_name = "demo-vpc-network"
  project_id   = var.project_id
}

module "vpc_subnetwork" {
  source       = "../modules/subnetwork"
  network_name = module.vpc_network.network_name
  project_id   = var.project_id
  subnetworks = [
    {
      subnet_name           = "demo-subnet",
      ip_cidr               = "10.0.1.0/24",
      region                = "us-central1",
      subnet_private_access = true,
      secondary_ranges = {
        "demo-gke-pods-range"     = "10.4.0.0/18",
        "demo-gke-services-range" = "10.8.0.0/20"
      }
    },
    {
      subnet_name           = "demo-subnet-db"
      region                = "us-central1"
      ip_cidr               = "10.0.2.0/24"
      subnet_private_access = true
    }
  ]
}

module "cloud_nat_gateway" {
  source     = "../modules/cloud_nat"
  project_id = var.project_id
  vpc_router = [
    {
      name         = "demo-router-us-central1"
      network_name = module.vpc_network.network_name
      region       = var.region
    }
  ]
  cloud_nat = [
    {
      nat_name                           = "demo-cloud-nat-us-central1"
      router_name                        = "demo-router-us-central1"
      region                             = "us-central1"
      source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
      nat_ip_allocate_option             = "MANUAL_ONLY"
      nat_ips = [
        "demo-nat-ip-1",
      ]
    },
    # {
    #   nat_name                           = "demo-cloud-nat-us-central1-secondary"
    #   router_name                        = "demo-router-us-central1"
    #   nat_ip_allocate_option             = "MANUAL_ONLY"
    #   nat_ips                            = ["demo-nat-ip-2", "demo-nat-ip-3"]
    #   region                             = "us-central1"
    #   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    #   subnetwork_ip_ranges_to_nat_list = [
    #     {
    #       subnetwork_name         = "demo-subnet-db"
    #       source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
    #     },
    #     {
    #       subnetwork_name          = "demo-subnet"
    #       source_ip_ranges_to_nat  = ["LIST_OF_SECONDARY_IP_RANGES"]
    #       secondary_ip_range_names = ["demo-gke-pods-range"]
    #     }
    #   ]
    # }
  ]
}
