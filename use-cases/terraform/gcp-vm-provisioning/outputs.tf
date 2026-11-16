output "instance_name" {
  description = "Created Compute Engine instance name."
  value       = google_compute_instance.ubuntu_instance.name
}

output "instance_zone" {
  description = "Zone containing the instance."
  value       = google_compute_instance.ubuntu_instance.zone
}

output "internal_ip" {
  description = "Internal IPv4 address assigned to the instance."
  value       = google_compute_instance.ubuntu_instance.network_interface[0].network_ip
}

output "public_ip" {
  description = "External IPv4 address, or null when assign_public_ip is false."
  value       = try(google_compute_instance.ubuntu_instance.network_interface[0].access_config[0].nat_ip, null)
}
