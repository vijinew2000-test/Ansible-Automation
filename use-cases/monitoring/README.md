# Monitoring Automation Use Cases

This category contains Ansible automation for installing, configuring, and verifying monitoring components on managed systems.

## Included use cases

- [SNMP installation and configuration on Ubuntu VDIs](snmp-installation-ubuntu/README.md)

## Safety principles

- Keep monitoring credentials and SNMP community strings in Unity inventory, Ansible Vault, or an approved secret manager.
- Restrict monitoring access to approved source addresses.
- Replace documentation-only addresses through protected inventory.
- Verify service state after deployment and test remote monitoring connectivity separately.
- Use staged execution and `--limit` for large rollouts.
- Record when a playbook deliberately restarts a service on every execution.
