variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Variable for subnetworks
variable "subnetworks" {
  description = "A list of subnetworks to create in the VPC network"
  type = list(object({
    subnet_name           = string
    ip_cidr               = string
    region                = string
    description           = optional(string)
    subnet_private_access = optional(bool, false)
    secondary_ranges      = optional(map(string))
  }))
  default = []
}