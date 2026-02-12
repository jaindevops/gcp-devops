variable "global_ip" {
  type        = list(string)
  description = "A list of global IP addresses to create"
  default     = []
}

resource "google_compute_global_address" "global_ip" {
  # for_each = { for ip in var.global_ip : ip => ip }
  for_each = toset(var.global_ip)

  name    = each.value
  project = var.project_id

}