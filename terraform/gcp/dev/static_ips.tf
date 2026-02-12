module "static_ips" {
  source = "../../modules/static_ips"

  project_id = var.project_id
  global_ip = [
    "demo-lb-ip",
  ]
}