# Hyper-V Automation with Ansible

This use case manages a Microsoft Hyper-V host from Ansible through WinRM.

## Included playbooks

```text
hyper-v-automation/
├── README.md
├── test-hyperv-host-connectivity.yml
├── create-vm-checkpoint.yml
└── list-vm-checkpoints.yml
```

### 1. Hyper-V host connectivity test

`test-hyperv-host-connectivity.yml` confirms that Ansible can authenticate to and execute a Windows module on the Hyper-V host through WinRM.

Expected successful result:

```text
ping: pong
```

This is an Ansible/WinRM connectivity test, not an ICMP network ping.

### 2. Hyper-V VM checkpoint creation

`create-vm-checkpoint.yml`:

1. Tests connectivity to the Hyper-V host.
2. Finds the requested VM by name.
3. Creates a timestamped checkpoint.
4. Queries Hyper-V to confirm that the checkpoint exists.
5. Returns the VM name, checkpoint name, creation time, and status.

The guest Windows VM's IP address is not required. The playbook connects to the **Hyper-V host** and selects the guest using `vm_name`.

## Example values

The committed host address `192.0.2.10` belongs to the documentation-only TEST-NET range. Replace it with the approved Hyper-V host address in your secure runtime configuration.

`win-test-01` is an example VM name. Replace it with the exact name returned by `Get-VM`.

## Requirements

- Hyper-V role and PowerShell Hyper-V module installed on the target host.
- WinRM enabled and reachable from the Ansible execution environment.
- The supplied account must be allowed to connect through WinRM.
- The account must have permission to read VMs and create checkpoints.
- The `ansible.windows` collection must be installed.

```bash
ansible-galaxy collection install ansible.windows
```

## Credentials

Do not store real usernames or passwords in Git. Supply them through Unity One runtime inputs, protected inventory variables, Ansible Vault, or an approved secret manager.

## Test connectivity

```bash
ansible-playbook use-cases/windows/hyper-v-automation/test-hyperv-host-connectivity.yml
```

Success means the Hyper-V host is reachable and the supplied credentials are accepted.

## Create a checkpoint

Before execution, confirm the exact VM name and available checkpoint storage capacity.

```bash
ansible-playbook use-cases/windows/hyper-v-automation/create-vm-checkpoint.yml
```

A successful run reports a checkpoint name similar to:

```text
Unity-20261021-143012-123
```

## Safety notes

- Test only against the approved lab Hyper-V host first.
- A checkpoint is not a backup.
- Checkpoints consume storage and may grow while retained.
- Do not create repeated checkpoints without a retention and deletion plan.
- Never use production host credentials or addresses in this public repository.


### 3. List checkpoints for a VM

`list-vm-checkpoints.yml` is a read-only playbook for operators who do not log in to the Hyper-V Manager UI.

The operator supplies the Hyper-V host connection and exact VM name. Unity returns:

- VM name
- Total checkpoint count
- Checkpoint name
- Creation time in the Hyper-V host's local time
- Unique checkpoint ID

The results are sorted from newest to oldest. The unique ID is useful for selecting an exact checkpoint in a later deletion workflow, especially when names are similar.

Run it with:

```bash
ansible-playbook use-cases/windows/hyper-v-automation/list-vm-checkpoints.yml
```

This playbook sets `$Ansible.Changed = $false`; it only reads Hyper-V state and does not create, modify, or remove a checkpoint.
