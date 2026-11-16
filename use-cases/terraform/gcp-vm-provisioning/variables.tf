variable "project" {
  type        = string
  description = "The Google Cloud project ID in which to deploy the VM."
}

variable "region" {
  type        = string
  description = "The Google Cloud region used by the provider."
}

variable "zone" {
  type        = string
  description = "The Google Cloud zone in which to deploy the VM."
}

variable "instance_name" {
  type        = string
  description = "Name of the Google Compute Engine instance."
}

variable "machine_type" {
  type        = string
  description = "Machine type for the instance."
  default     = "e2-micro"
}

variable "image" {
  type        = string
  description = "Boot-disk image family or image self-link."
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "network" {
  type        = string
  description = "VPC network name or self-link."
  default     = "default"
}

variable "username" {
  type        = string
  description = "Linux username associated with the SSH public key."

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*$", var.username))
    error_message = "username must be a valid lowercase Linux username."
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content used to access the VM."
  sensitive   = true
}

variable "credentials_file" {
  type        = string
  description = "Optional path to a Google Cloud service-account JSON key. Prefer Application Default Credentials."
  default     = null
  nullable    = true
}

variable "boot_disk_size_gb" {
  type        = number
  description = "Boot-disk size in GiB."
  default     = 20

  validation {
    condition     = var.boot_disk_size_gb >= 10
    error_message = "boot_disk_size_gb must be at least 10 GiB."
  }
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign an ephemeral external IPv4 address."
  default     = false
}

variable "network_tags" {
  type        = list(string)
  description = "Optional network tags applied to the VM. Firewall rules are not created by this example."
  default     = []
}
