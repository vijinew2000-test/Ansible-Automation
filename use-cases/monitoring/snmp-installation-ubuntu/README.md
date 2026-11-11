# SNMP Installation and Configuration on Ubuntu VDIs

## Purpose

`install-configure-snmp-ubuntu.yml` installs the Ubuntu SNMP packages, opens the SNMP daemon listener beyond localhost, restricts read-only access to approved monitoring servers, restarts the service, enables it at boot, and verifies that it is active.

## What the playbook does

1. Targets inventory-selected Ubuntu hosts using `hosts: all`.
2. Uses root privilege escalation.
3. Uses `/tmp/.ansible-remote/tmp` when the SSH user's home directory is unsuitable for Ansible temporary files.
4. Uses a 60-second SSH timeout.
5. Validates that a protected SNMP community and monitoring-server list are available.
6. Installs packages matching `snmp*`.
7. Comments the default localhost-only `agentaddress` line and keeps a backup.
8. Adds `agentAddress udp:161,udp6:[::1]:161`.
9. Adds one restricted read-only community rule for each approved monitoring server.
10. Restarts and enables `snmpd`.
11. Verifies that `systemctl is-active snmpd` returns `active`.

## Protected and example values

The repository contains only documentation-safe TEST-NET addresses:

```yaml
monitoring_servers:
  - "192.0.2.10"
  - "192.0.2.11"
```

Override them through protected Unity or inventory variables.

The real community is not stored in Git:

```yaml
snmp_community: "{{ vault_snmp_community }}"
```

Store `vault_snmp_community` in Unity, Ansible Vault, or an approved secret manager.

## Execution

Because the play uses `hosts: all`, select the required VDI using Unity's target selection or Ansible `--limit`. Inventory supplies the common SSH user and credentials.

```bash
ansible-playbook -i inventories/production/hosts.yml \
  use-cases/monitoring/snmp-installation-ubuntu/install-configure-snmp-ubuntu.yml \
  --limit TARGET_INVENTORY_HOST
```

Use the approved secret-loading method for `vault_snmp_community`.

## Expected result

```text
VM: <inventory-host>
SNMP service: active
SNMP installation and configuration completed successfully
```

This confirms that the service is active. It does not prove that UDP 161 is reachable from the monitoring platform; verify host firewall, network ACLs, routing, and a remote SNMP poll separately.

## Operational notes

- This version deliberately restarts `snmpd` on every execution.
- `ansible_remote_tmp` uses a fixed path because shell-style `${USER}` expansion does not occur inside this Ansible YAML variable.
- Test with one VDI using `--limit` before a wider rollout.
- Review whether the `snmp*` package wildcard is appropriate for the approved Ubuntu image.

## Security notes

- SNMPv2c community strings are shared secrets and are not encrypted on the network.
- Limit UDP 161 with host and network firewalls to approved monitoring servers.
- Prefer SNMPv3 where authentication and encryption are required.
