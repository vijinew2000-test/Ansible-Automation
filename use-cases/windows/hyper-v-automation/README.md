# Hyper-V Automation with Ansible

This use case manages a Microsoft Hyper-V host from Ansible through WinRM.

## Included playbooks

```text
hyper-v-automation/
├── README.md
├── hyper-v-connection-test.yml
├── hyper-v-checkpoint-creation.yml
├── hyper-v-list-checkpoints.yml
├── hyper-v-vm-checkpoint-deletion.yml
├── hyper-v-vm-change-cpu-memory.yml
└── hyper-v-host-vm-capacity-report.yml
```

### 1. Hyper-V host connectivity test

`hyper-v-connection-test.yml` confirms that Ansible can authenticate to and execute a Windows module on the Hyper-V host through WinRM.

Expected successful result:

```text
ping: pong
```

This is an Ansible/WinRM connectivity test, not an ICMP network ping.

### 2. Hyper-V VM checkpoint creation

`hyper-v-checkpoint-creation.yml`:

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
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-connection-test.yml
```

Success means the Hyper-V host is reachable and the supplied credentials are accepted.

## Create a checkpoint

Before execution, confirm the exact VM name and available checkpoint storage capacity.

```bash
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-checkpoint-creation.yml
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

`hyper-v-list-checkpoints.yml` is a read-only playbook for operators who do not log in to the Hyper-V Manager UI.

The operator supplies the exact VM name. The Hyper-V host address and credentials come from Unity or protected Ansible inventory. Unity returns:

- VM name
- Total checkpoint count
- Checkpoint name
- Creation time in the Hyper-V host's local time
- Unique checkpoint ID

The results are sorted from newest to oldest. The unique ID is useful for selecting an exact checkpoint in a later deletion workflow, especially when names are similar.

Run it with:

```bash
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-list-checkpoints.yml
```

The play targets `hosts: all` and runs directly on each inventory-selected Hyper-V host; it does not use localhost delegation or embed host credentials. It sets `$Ansible.Changed = $false` and does not create, modify, or remove a checkpoint.


### 4. Delete a selected VM checkpoint

`hyper-v-vm-checkpoint-deletion.yml` deletes one explicitly selected checkpoint for one VM.

Recommended operator flow:

```text
Enter Hyper-V host and VM name
              ↓
Run hyper-v-list-checkpoints.yml
              ↓
Review checkpoint name, creation time and ID
              ↓
Enter the exact checkpoint name
              ↓
Run hyper-v-vm-checkpoint-deletion.yml
              ↓
Verify status is DELETED or ALREADY ABSENT
```

The playbook:

- Confirms WinRM connectivity to the Hyper-V host.
- Requires a non-empty checkpoint name.
- Confirms exactly one VM matches `vm_name`.
- Stops if multiple checkpoints share the requested name.
- Returns `ALREADY ABSENT` without reporting a change when no match exists.
- Deletes the selected checkpoint without an interactive prompt.
- Queries Hyper-V again and verifies that the deleted checkpoint ID no longer exists.
- Returns the VM, checkpoint name and final status.

Run it with:

```bash
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-vm-checkpoint-deletion.yml
```

Checkpoint deletion is destructive and may trigger AVHDX merge activity. Confirm the VM, checkpoint, storage health and retention approval before execution.


### 5. Hyper-V VM change CPU & memory

`hyper-v-vm-change-cpu-memory.yml` changes the virtual processor count and fixed startup memory for one VM, then verifies the requested values and restores the VM's original running state.

The playbook:

- Confirms WinRM connectivity to the Hyper-V host.
- Requires exactly one VM matching `vm_name`.
- Validates CPU count against the host logical processor count.
- Requires at least 1 GB of memory.
- Supports fixed-memory VMs only; dynamic-memory VMs are rejected.
- Makes no changes when CPU and memory already match.
- Requires `allow_restart: true` before shutting down a running VM.
- Checks available host memory before increasing VM memory.
- Restarts the VM only when it was running before the change.
- Verifies the final CPU, memory, and VM state.

Run it with:

```bash
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-vm-change-cpu-memory.yml
```

Changing these resources can interrupt service because a running VM must be shut down. Use an approved maintenance window, confirm host capacity, and take a suitable backup or checkpoint according to your change policy.


### 6. Report Hyper-V host and VM capacity

`hyper-v-host-vm-capacity-report.yml` is a read-only capacity and inventory report. Run it before planning VM CPU, memory, or virtual-disk changes.

It reports:

- Total VM count and running VM count.
- Host logical processor count.
- Configured vCPU totals for all VMs and running VMs.
- Host total and currently free physical memory.
- Each VM's state, vCPU count, dynamic-memory setting, configured memory, and current assigned memory.
- Each attached VHD/VHDX path, type, virtual capacity, current file size, controller location, and parent path when applicable.
- Each host volume's total capacity, free capacity, and free percentage.
- Pass-through disks and VHD read errors that require separate inspection.

Run it with:

```bash
ansible-playbook use-cases/windows/hyper-v-automation/hyper-v-host-vm-capacity-report.yml
```

The target Hyper-V hosts and credentials should come from protected inventory or runtime inputs. The playbook sets `$Ansible.Changed = $false` and performs no resource changes.

For virtual-disk expansion, verify the free space on the host volume containing the VHD/VHDX. CPU allocation is not a fixed consumable pool, so configured vCPU totals are reported for planning without presenting a misleading calculated “remaining vCPU” value.
