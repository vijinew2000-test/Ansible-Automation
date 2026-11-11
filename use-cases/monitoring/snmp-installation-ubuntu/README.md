# SNMP Installation and Configuration on Ubuntu VDIs

## Purpose

`install-configure-snmp-ubuntu.yml` installs the Ubuntu SNMP client and daemon, restricts read-only access to approved monitoring servers, starts the service, and verifies that it is active and listening on UDP port 161.

## What the playbook does

1. Targets the inventory host selected through `target_ip`.
2. Validates that a protected SNMP community and monitoring-server list are available.
3. Installs `snmp` and `snmpd`.
4. Configures SNMP to listen on IPv4 UDP 161 and IPv6 loopback.
5. Removes existing unmanaged `rocommunity` and `rocommunity6` entries.
6. Adds one restricted read-only community rule per approved monitoring server.
7. Restarts SNMP only when configuration changes.
8. Enables `snmpd` at boot.
9. Verifies the service and UDP 161 listener.

## Inputs

The committed addresses are documentation-only TEST-NET examples:

```yaml
monitoring_servers:
  - "192.0.2.10"
  - "192.0.2.11"
```

Replace them through protected Unity or inventory variables. Do not commit production monitoring addresses.

The community is not stored in Git:

```yaml
snmp_community: "{{ vault_snmp_community }}"
```

Store `vault_snmp_community` in Unity, Ansible Vault, or an approved secret manager.

## Execution

The target IP must match a host known to the selected Ansible/Unity inventory. Inventory supplies the shared connection user and credentials.

```bash
ansible-playbook -i inventories/production/hosts.yml \
  use-cases/monitoring/snmp-installation-ubuntu/install-configure-snmp-ubuntu.yml \
  --extra-vars "target_ip=TARGET_INVENTORY_HOST" \
  --limit TARGET_INVENTORY_HOST
```

Use the approved secret-loading method for `vault_snmp_community`.

## Expected result

The play finishes with:

```text
SNMP service is installed, running, and listening on <inventory-host>
```

A successful result confirms that `snmpd` is active and UDP port 161 is listening. It does not prove that a remote monitoring server can reach the VM; firewall, routing, and monitoring-side polling must be verified separately.

## Security notes

- SNMPv2c community strings are shared secrets and are not encrypted on the network.
- Limit UDP 161 with host and network firewalls to approved monitoring servers.
- Prefer SNMPv3 where authentication and encryption are required.
- Test on one approved VDI before rolling out to the remaining systems.
