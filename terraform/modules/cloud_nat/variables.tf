variable "region" {
  type        = string
  description = "The region where the Cloud NAT resources will be created"
  default     = "us-central1"
}

variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = ""
}

variable "vpc_router" {
  type = list(object({
    name         = string
    network_name = string
    region       = string
  }))
  description = "A list of routers to create Cloud NAT on"
  default     = []
}

variable "cloud_nat" {
  type = list(object({
    nat_name                           = string
    router_name                        = string
    nat_ip_allocate_option             = string # "AUTO_ONLY" or "MANUAL_ONLY"
    source_subnetwork_ip_ranges_to_nat = string # "ALL_SUBNETWORKS_ALL_IP_RANGES", "ALL_SUBNETWORKS_PRIMARY_IP_RANGES", "LIST_OF_SUBNETWORKS"
    enable_dynamic_port_allocation     = optional(bool, false)
    nat_ips                            = optional(list(string), []) # List of NAT IP names (only for MANUAL_ONLY)
    enable_logging                     = optional(bool, false)
    log_filter                         = optional(string, "ERRORS_ONLY") # "ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"
    min_ports_per_vm                   = optional(number, null)
    max_ports_per_vm                   = optional(number, null)
    region                             = string # The region for the Cloud NAT gateway
    subnetwork_ip_ranges_to_nat_list = optional(list(object({
      subnetwork_name          = string
      source_ip_ranges_to_nat  = list(string) # "ALL_IP_RANGES", "PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"
      secondary_ip_range_names = optional(list(string), [])
    })), [])
  }))
  description = "A list of Cloud NAT configurations"
  default     = []
}