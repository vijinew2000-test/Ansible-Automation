# GCP VM Provisioning with Terraform

## Purpose

This Terraform example provisions one Ubuntu Compute Engine VM with configurable project, region, zone, machine type, boot disk, VPC network, SSH access, network tags, and optional public IP.

## Structure

```text
gcp-vm-provisioning/
├── README.md
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars.example
```

## What it creates

- One `google_compute_instance`.
- Ubuntu boot disk using the selected image.
- One VPC network interface.
- SSH access through a public key.
- Optional ephemeral external IP.
- Terraform management labels.
- Outputs for the instance name, zone, internal IP, and optional public IP.

This example does not create a VPC, subnet, firewall rule, custom service account, or private key.

## Security improvement from the original draft

The original password-based startup script was intentionally not committed. A VM password placed inside `metadata_startup_script` can appear in Terraform state, plans, logs, and instance metadata.

This version uses:

```hcl
metadata = {
  ssh-keys = "${var.username}:${trimspace(var.ssh_public_key)}"
}
```

Only provide a public SSH key. Never commit a private key.

## Authentication

The provider uses Application Default Credentials when `credentials_file` is null.

For an interactive lab:

```bash
gcloud auth application-default login
```

For automation, prefer workload identity or another approved keyless method. If a service-account JSON file is required, keep it outside Git and provide its local path through `credentials_file`.

## Usage

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`, then run:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Review the plan before approving `terraform apply`.

To remove the lab VM:

```bash
terraform destroy
```

## Public IP

The safe default is:

```hcl
assign_public_ip = false
```

Set it to `true` only when an external IP is required and approved. This module does not create firewall rules.

## Service-account warning

The VM currently attaches the project's default Compute Engine service account with the `cloud-platform` OAuth scope, matching the supplied draft. For production, replace it with a dedicated least-privilege service account and restrict its IAM roles.

## Files that must not be committed

- `terraform.tfvars`
- `*.tfstate` and state backups
- `.terraform/`
- Terraform plan files
- Service-account JSON keys
- SSH private keys
