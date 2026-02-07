# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version    = "40.0.0"
  project_id = var.project_id
  name       = "demo-cluster"
  region     = var.region
  # zones                      = [local.primary_zone, local.secondary_zone]
  zones                      = [local.primary_zone]
  network                    = module.vpc_network.network_name
  subnetwork                 = module.vpc_subnetwork.subnet_names[0]
  ip_range_pods              = module.vpc_subnetwork.subnetworks_detailed[0].secondary_ip_ranges[0].range_name
  ip_range_services          = module.vpc_subnetwork.subnetworks_detailed[0].secondary_ip_ranges[1].range_name
  create_service_account     = false
  http_load_balancing        = false
  network_policy             = true
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_private_endpoint    = false
  enable_private_nodes       = true
  dns_cache                  = false
  remove_default_node_pool   = true
  master_authorized_networks = [
    {
      cidr_block   = "122.172.81.158/32"
      display_name = "Home IP"
    }
  ]

  node_pools = [
    {
      name         = "demo-node-pool"
      machine_type = "e2-medium"
      # node_locations     = "${local.primary_zone}, ${local.secondary_zone}"
      node_locations     = "${local.primary_zone}"
      initial_node_count = 1
      min_count          = 1
      max_count          = 5
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "gke-sa@${var.project_id}.iam.gserviceaccount.com"
      preemptible        = false
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    demo-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    demo-node-pool = merge(
      {
        "node-label" = "demo-app"
      },
      local.labels
    )
  }

  node_pools_resource_labels = {
    all = {}
  }

  node_pools_metadata = {
    all = {}

    demo-node-pool = {
      block-project-ssh-keys = true
    }
  }

  node_pools_taints = {
    all = []

    # demo-node-pool = [
    #   {
    #     key    = "demo-node-pool"
    #     value  = true
    #     effect = "PREFER_NO_SCHEDULE"
    #   },
    # ]
  }

  node_pools_tags = {
    all = []

  }
}