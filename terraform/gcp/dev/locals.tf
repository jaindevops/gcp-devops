locals {
  name_prefix    = "demo"
  network_name   = "${local.name_prefix}-vpc"
  primary_zone   = "us-central1-a"
  secondary_zone = "us-central1-c"
  labels = {
    env = "demo"
  }
}