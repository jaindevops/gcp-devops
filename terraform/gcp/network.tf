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
