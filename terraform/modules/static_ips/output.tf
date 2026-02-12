output "global_ip_addresses" {
  description = "A map of global IP names to their assigned IP addresses."
  value       = { for ip in google_compute_global_address.global_ip : ip.name => ip.address }
}
  