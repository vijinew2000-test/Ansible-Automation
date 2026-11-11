# Monitoring Automation Use Cases

This category contains Ansible automation for installing, configuring, and verifying monitoring components on managed systems.

## Included use cases

- [SNMP installation and configuration on Ubuntu VDIs](snmp-installation-ubuntu/README.md)

## Safety principles

- Keep monitoring credentials and SNMP community strings in Unity inventory, Ansible Vault, or an approved secret manager.
- Restrict monitoring access to approved source addresses.
- Remove insecure default configuration.
- Restart services only when configuration changes.
- Verify both service state and listening ports after deployment.
- Use staged execution and `--limit` for large rollouts.
