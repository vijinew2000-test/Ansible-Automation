# Zabbix Agent 2 Installation on Windows

This use case automates the discovery, installation or upgrade, configuration, restart, and verification of Zabbix Agent 2 on Windows Server 2016 and later.

## Current phase: discovery

The first playbook is:

```text
check-existing-installation.yml
```

It performs a read-only check before any installation or upgrade.

It reports:

- Windows hostname
- Existing Windows services containing `Zabbix`
- Service name and display name
- Service state and startup mode
- Service account
- Executable path and arguments
- Whether the expected Agent 2 executable exists
- Installed executable version
- Whether the expected configuration file exists
- Configured `Server`, `ServerActive`, `Hostname`, and `uladmin.OSVersion` UserParameter

## Why discovery comes first

A target may contain:

- A working Zabbix Agent 2 installation
- An older Zabbix Agent version
- Leftover files without a registered service
- A service using a non-default executable or configuration path
- A partially completed installation

Discovery prevents the installation playbook from making incorrect assumptions.

## Requirements

- Ansible control node with the `ansible.windows` collection
- Network access from the control node to the Windows host on the configured WinRM port
- A WinRM account permitted to query Windows services and read the installation files
- The Windows host added to an inventory

Install the Windows collection:

```bash
ansible-galaxy collection install ansible.windows
```

## Run the discovery

Syntax check:

```bash
ansible-playbook -i inventory/hosts.yml   use-cases/windows/zabbix-agent2-installation/check-existing-installation.yml   --syntax-check
```

Run against one test server first:

```bash
ansible-playbook -i inventory/hosts.yml   use-cases/windows/zabbix-agent2-installation/check-existing-installation.yml   --limit WINDOWS_TEST_HOST
```

Replace `WINDOWS_TEST_HOST` with the exact inventory hostname.

## Expected results

If Agent 2 exists, the output shows the service, executable version, expected paths, and selected configuration values.

If it does not exist, the playbook reports:

```text
No Zabbix Windows service found.
Agent 2 executable exists: False
Agent 2 config not found at the expected path
```

These messages are discovery results, not playbook failures.

## Safety notes

- This playbook is read-only and uses `changed_when: false`.
- It does not install, upgrade, modify, restart, or remove anything.
- `become: false` means tasks run using the connected WinRM account.
- WinRM Basic authentication on port 5985 sends authentication through HTTP-level transport. Use it only within an approved protected network or replace it with the organisation's approved secure WinRM configuration.
- Do not commit Windows passwords to Git. Store them in Ansible Vault or an approved secret manager.

## Planned full workflow

```text
Discover existing installation
        ↓
Decide install, upgrade, or configure
        ↓
Download or copy approved MSI
        ↓
Back up existing configuration
        ↓
Install or upgrade Agent 2
        ↓
Set Server, ServerActive, Hostname, and UserParameter
        ↓
Restart Zabbix Agent 2
        ↓
Verify service, version, configuration, port, and custom metric
```


## Final installation and configuration playbook

The state-changing playbook is:

```text
install-configure-zabbix-agent2.yml
```

It performs the following operations in batches of five Windows hosts:

1. Validates `Server`, `ServerActive`, and `Hostname`.
2. Downloads the pinned Zabbix Agent 2 version `7.0.31` MSI.
3. Installs or upgrades the agent quietly without restarting Windows.
4. Confirms the executable and configuration file exist.
5. Creates a one-time configuration backup.
6. Updates `Server`, `ServerActive`, and `Hostname` without duplicate entries.
7. Adds or updates the `uladmin.OSVersion` UserParameter.
8. Restarts Agent 2 only when configuration changes.
9. Ensures the service starts automatically and is running.
10. Verifies the agent version, custom OS metric, and service state.

The committed `10.10.10.10` value is an example. Replace it or override `zabbix_server` from the Unity One inventory before execution.

Syntax check:

```bash
ansible-playbook -i inventory/hosts.yml \
  use-cases/windows/zabbix-agent2-installation/install-configure-zabbix-agent2.yml \
  --syntax-check
```

Run against one test host first:

```bash
ansible-playbook -i inventory/hosts.yml \
  use-cases/windows/zabbix-agent2-installation/install-configure-zabbix-agent2.yml \
  --limit WINDOWS_TEST_HOST
```

Only after the test host passes installation, configuration, metric, and service validation should the playbook be allowed to continue to additional hosts.


## Separated OS metric script version

The newer playbook is:

```text
configure-zabbix-agent2.yml
```

This version creates the reusable metric script at:

```text
C:\Program Files\Zabbix Agent 2\scripts\Get-OSVersion.ps1
```

It then adds a single `uladmin.OSVersion` UserParameter that calls the script. It also:

- Rejects the placeholder Zabbix server value before making changes.
- Avoids duplicate `Server`, `ServerActive`, `Hostname`, and UserParameter entries.
- Keeps a one-time `.unityone-backup` of the original configuration.
- Reports changed status only when the script or configuration differs.
- Restarts Agent 2 through a handler only when a change occurs.
- Tests the custom metric through the Agent 2 executable.
- Processes Windows hosts in batches of five.

Before execution, supply the approved server or proxy address through inventory or replace the placeholder.

Syntax check:

```bash
ansible-playbook -i inventory/hosts.yml \
  use-cases/windows/zabbix-agent2-installation/configure-zabbix-agent2.yml \
  --syntax-check
```

Test one Windows host first:

```bash
ansible-playbook -i inventory/hosts.yml \
  use-cases/windows/zabbix-agent2-installation/configure-zabbix-agent2.yml \
  --limit WINDOWS_TEST_HOST
```
