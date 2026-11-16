resource "google_compute_instance" "ubuntu_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = var.network

    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    ssh-keys = "${var.username}:${trimspace(var.ssh_public_key)}"
  }

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = var.network_tags

  labels = {
    managed-by = "terraform"
    workload   = "gcp-vm-provisioning"
  }

  lifecycle {
    precondition {
      condition     = var.assign_public_ip || var.network != ""
      error_message = "A valid VPC network must be supplied."
    }
  }
}
