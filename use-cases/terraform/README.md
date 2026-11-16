# Terraform Use Cases

This category contains infrastructure-as-code examples for repeatable cloud provisioning.

## Included use cases

- [GCP VM provisioning](gcp-vm-provisioning/README.md)

## Safety principles

- Review `terraform plan` before applying.
- Keep state in an approved protected backend.
- Never commit state, variable files containing environment data, service-account keys, or private SSH keys.
- Prefer keyless cloud authentication.
- Use least-privilege service accounts.
- Default to private networking and add public access only when approved.
- Destroy temporary lab resources when testing is complete.
