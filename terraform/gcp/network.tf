module "vpc_network" {
  source       = "../modules/network"
  network_name = "demo-vpc-network"
  project_id   = var.project_id
}