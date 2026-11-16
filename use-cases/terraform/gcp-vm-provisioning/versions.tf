terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region

  # Leave null to use Application Default Credentials.
  credentials = var.credentials_file == null ? null : file(var.credentials_file)
}
