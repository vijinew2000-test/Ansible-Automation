# Ansible Automation

A practical learning and automation repository for Linux, Windows, services, containers, monitoring, configuration management, and safe remediation.

This repository is intended for DevOps engineers who want to understand both **how Ansible works** and **how to use it safely in real operational scenarios**.

## 1. What Ansible is

Ansible is an agentless automation tool.

- The **control node** is the machine where Ansible is installed.
- **Managed nodes** are the target Linux, Windows, network, or other systems.
- Linux targets are normally managed through **SSH**.
- Windows targets are normally managed through **WinRM**.
- Instructions are written in YAML files called **playbooks**.
- Ansible modules perform actions such as installing packages, copying files, changing configuration, and managing services.

Basic flow:

```text
Engineer or automation platform
          |
          v
Ansible control node
          |
          +---- SSH ----> Linux hosts
          |
          +--- WinRM ---> Windows hosts
          |
          +---- API ----> Cloud and network services
```

Ansible usually does not require a permanent agent on the managed node.

## 2. Why DevOps engineers use Ansible

Ansible helps us perform the same operation consistently across one server or hundreds of servers.

Common uses:

- Install and upgrade packages.
- Deploy configuration files.
- Create users, groups, and directories.
- Start, stop, restart, and enable services.
- Deploy applications.
- Configure NGINX, Docker, databases, monitoring agents, and collectors.
- Perform read-only health investigations.
- Apply approved remediations.
- Verify that a change worked.
- Produce repeatable logs and execution results.

## 3. Core Ansible components

| Component | Simple meaning |
|---|---|
| Control node | Machine that runs Ansible |
| Managed node | Target machine being automated |
| Inventory | List of target hosts and groups |
| Playbook | YAML file describing the automation |
| Play | Connects a group of hosts to a set of tasks |
| Task | One automation step |
| Module | Ansible function such as `copy`, `package`, or `service` |
| Variable | Reusable value such as a package name or path |
| Fact | Information collected from a target host |
| Register | Saves task output into a variable |
| Condition | Runs a task only when a rule is true |
| Handler | Runs only when notified by a changed task |
| Role | Reusable automation structure |
| Collection | Packaged modules, roles, and plugins |
| Template | Jinja2-based configuration file |
| Vault | Encrypts sensitive Ansible data |

## 4. Basic repository structure

```text
Ansible-Automation/
├── README.md
├── ansible.cfg
├── inventories/
│   ├── lab/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── production/
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
│   ├── investigation/
│   ├── remediation/
│   ├── simulation/
│   └── verification/
├── roles/
├── templates/
├── files/
└── docs/
```

Do not commit passwords, SSH private keys, tokens, certificates, or vault passwords.

## 5. Inventory basics

Example Linux inventory:

```yaml
---
all:
  children:
    linux:
      hosts:
        lab-server:
          ansible_host: REPLACE_WITH_HOST
          ansible_user: REPLACE_WITH_USER
```

Test connectivity:

```bash
ansible all -i inventories/lab/hosts.yml -m ping
```

The Ansible `ping` module does not send an ICMP ping. It checks whether Ansible can connect and execute Python on the Linux target.

Example Windows connection variables:

```yaml
ansible_connection: winrm
ansible_port: 5985
ansible_winrm_transport: basic
ansible_winrm_server_cert_validation: ignore
ansible_become: false
```

For Windows, privilege comes from the connected WinRM account. Linux-style `sudo` is not used in the same way.

## 6. Playbook anatomy

```yaml
---
- name: Ensure NGINX is installed and running
  hosts: linux
  gather_facts: true
  become: true

  tasks:
    - name: Install NGINX
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Start and enable NGINX
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

Meaning:

- `hosts` selects inventory targets.
- `gather_facts` collects OS and hardware information.
- `become: true` uses privilege escalation, normally sudo on Linux.
- `tasks` contains the ordered steps.
- Fully qualified module names such as `ansible.builtin.service` make the source clear.
- `state: present` and `state: started` describe the desired state.

## 7. Essential commands

Check the installed version:

```bash
ansible --version
ansible-playbook --version
```

List inventory:

```bash
ansible-inventory -i inventories/lab/hosts.yml --graph
```

Check Linux connectivity:

```bash
ansible all -i inventories/lab/hosts.yml -m ping
```

Run a playbook:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/example.yml
```

Check YAML and playbook syntax:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/example.yml --syntax-check
```

Preview supported changes:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/example.yml --check --diff
```

Run against one host:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/example.yml --limit lab-server
```

Show more troubleshooting detail:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/example.yml -vv
```

Start with `-vv`. Use `-vvv` only when connection-level detail is required because verbose output can expose sensitive values.

## 8. Must-know Ansible concepts

### Idempotence

An idempotent playbook can run repeatedly without making unnecessary changes.

For example, `package: state=present` installs a missing package but does not reinstall it every time.

Prefer Ansible modules over raw shell commands because modules understand the target state.

### Variables

```yaml
vars:
  service_name: nginx
```

Use the value with Jinja syntax:

```yaml
name: "{{ service_name }}"
```

Variable precedence matters. Values can come from playbooks, inventory, `group_vars`, `host_vars`, roles, or `--extra-vars`.

### Registered output

```yaml
- name: Check disk usage
  ansible.builtin.command: df -PTh
  register: disk_result
  changed_when: false

- name: Show output
  ansible.builtin.debug:
    var: disk_result.stdout_lines
```

Important registered fields:

| Field | Meaning |
|---|---|
| `rc` | Return code; normally 0 means success |
| `stdout` | Standard output as one string |
| `stdout_lines` | Standard output split into lines |
| `stderr` | Error output |
| `changed` | Whether Ansible considers the task a change |
| `failed` | Whether the task failed |

### Conditions

```yaml
when: disk_result.rc == 0
```

Conditions use Jinja expressions. Do not wrap a complete `when` expression in `{{ }}`.

### changed_when and failed_when

Investigation commands should normally be read-only:

```yaml
changed_when: false
failed_when: false
```

- `changed_when: false` reports that the task collected information rather than modifying the host.
- `failed_when: false` allows the playbook to continue when a diagnostic command returns a nonzero code.

Use `failed_when: false` carefully. Always inspect `rc`, `stdout`, and `stderr`; otherwise a real failure may be hidden.

### Facts

Facts are information Ansible discovers from the managed host when `gather_facts: true`.

Examples include:

- Operating system and distribution
- Hostname
- IP addresses and interfaces
- CPU architecture and processor count
- Total and available memory
- Mounted filesystems
- Date and time
- Python interpreter information

View facts:

```bash
ansible all -i inventories/lab/hosts.yml -m ansible.builtin.setup
```

Filter facts:

```bash
ansible all -i inventories/lab/hosts.yml -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

Example condition:

```yaml
when: ansible_facts['os_family'] == 'Debian'
```

Disable facts with `gather_facts: false` when they are not needed. This makes short playbooks faster.

### Handlers

Handlers run only when a task reports a change.

```yaml
tasks:
  - name: Deploy NGINX configuration
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
      mode: "0644"
    notify: Restart NGINX

handlers:
  - name: Restart NGINX
    ansible.builtin.service:
      name: nginx
      state: restarted
```

### become

- `become: true`: request privilege escalation, normally sudo to root on Linux.
- `become: false`: run as the connected account.
- Use privilege escalation only for tasks that require it.
- The connected user still needs valid sudo permission.

### command, shell, and raw

| Module | Use |
|---|---|
| `command` | Run a command without shell features |
| `shell` | Use pipes, redirects, variables, or shell operators |
| `raw` | Run directly without requiring Python; use sparingly |

Prefer `command` over `shell` when pipes, redirects, and shell expansion are not required.

### Roles

Roles make automation reusable:

```text
roles/example/
├── defaults/main.yml
├── tasks/main.yml
├── handlers/main.yml
├── templates/
├── files/
└── vars/main.yml
```

Keep defaults overridable and place reusable task logic inside roles.

### Secrets

Use Ansible Vault or an approved secrets manager:

```bash
ansible-vault create group_vars/all/vault.yml
ansible-vault edit group_vars/all/vault.yml
```

Never place secrets directly in:

- Git
- README files
- Inventory committed to Git
- Playbook output
- Debug tasks
- LLM prompts
- CI/CD logs

Mark sensitive tasks with `no_log: true`, but remember that this reduces troubleshooting visibility.

## 9. Linux and OS automation use cases

These are the operational use cases covered in our learning and remediation work.

| Use case | Investigation | Typical approved response |
|---|---|---|
| High CPU | `top`, `ps`, load average, process/service mapping | Fix workload, tune service, scale, or controlled restart |
| Memory utilization | `free`, `vmstat`, process RSS, application metrics | Fix leak, tune limits, scale, or controlled restart |
| Swap usage | `free`, `swapon`, `vmstat`, per-process `VmSwap` | Fix memory pressure; avoid unsafe automatic `swapoff` |
| Disk space | `df`, `du`, logs, container storage | Approved cleanup, retention, rotation, or capacity increase |
| Inode exhaustion | `df -i`, file counts, high-entry directories | Remove approved obsolete files and fix file creation pattern |
| Service down | `systemctl status`, journal, port and process checks | Fix dependency/configuration and restart approved service |
| File-descriptor anomaly | `/proc/sys/fs/file-nr`, process FD counts and limits | Fix leak or adjust reviewed limits; do not kill arbitrary processes |
| Disk latency | `iostat`, `vmstat`, storage/application correlation | Fix I/O workload, storage issue, or capacity bottleneck |
| NGINX configuration drift | Compare baseline/saved configuration with `nginx -T` | Review diff, validate with `nginx -t`, then deploy approved config |
| Docker service/container down | Container state, logs, health check, host resources | Fix root cause, then restart or recreate the approved service |
| Zabbix Agent deployment | Detect version, install/upgrade, configure, restart, verify | Idempotent staged rollout with service and metric validation |
| Application/Celery service | Process, systemd/container state, logs, dependencies | Correct config/dependency, then controlled restart |
| Database health | Connectivity, service status, space, locks, sessions | Use database-specific reviewed remediation and backup first |

## 10. Investigation → remediation → verification pattern

Every operational automation should use this flow:

```text
Detect
  ↓
Investigate read-only evidence
  ↓
Identify root cause
  ↓
Propose a known remediation
  ↓
Human approval
  ↓
Execute with limited scope
  ↓
Verify service and business health
  ↓
Record result and rollback evidence
```

Example approval guard:

```yaml
vars:
  allow_remediation: false

tasks:
  - name: Require approval
    ansible.builtin.assert:
      that:
        - allow_remediation | bool
      fail_msg: "Remediation is blocked until it is explicitly approved."
```

Run an approved action:

```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/remediation.yml   --limit lab-server   --extra-vars "allow_remediation=true"
```

Approval alone is not enough. Confirm the target, evidence, impact, rollback, and verification method before running the playbook.

## 11. NGINX configuration-drift pattern

A drift check normally:

1. Reads the saved or approved baseline.
2. Captures the current effective configuration.
3. Compares both versions.
4. Registers the diff output.
5. Reports drift without changing the host.
6. Validates any proposed configuration with `nginx -t`.
7. Requires approval before deployment or reload.

Useful Ansible concepts for this pattern:

- `register`
- `rc`
- `stdout_lines`
- `changed_when: false`
- Carefully scoped `failed_when`
- `set_fact`
- Jinja conditions
- `debug`
- `become`
- Inventory host groups
- Idempotent read-only checks

## 12. Windows automation fundamentals

Windows automation commonly uses:

- WinRM for connection
- `ansible.windows.win_package` for MSI installation
- `ansible.windows.win_service` for services
- `ansible.windows.win_copy` for file transfer
- `ansible.windows.win_powershell` for PowerShell logic
- `ansible.windows.win_regedit` for registry values

For offline Windows servers, an approved package flow can be:

```text
Approved download source
        ↓
Jump server
        ↓
Ansible control node
        ↓
Windows target temporary directory
        ↓
Install → configure → restart → verify
```

For a large rollout, detect the current version first, back up the configuration, use `serial` for batches, verify each stage, and stop when validation fails.

## 13. Error handling and blocks

```yaml
- name: Deploy with recovery
  block:
    - name: Apply configuration
      ansible.builtin.template:
        src: app.conf.j2
        dest: /etc/example/app.conf
        mode: "0644"

    - name: Validate configuration
      ansible.builtin.command: example-service --check-config
      changed_when: false

  rescue:
    - name: Report deployment failure
      ansible.builtin.debug:
        msg: "Validation failed. Follow the approved rollback procedure."

  always:
    - name: Record completion
      ansible.builtin.debug:
        msg: "Automation attempt completed."
```

Use `block`, `rescue`, and `always` to make failure handling explicit. Do not claim rollback succeeded unless it was actually executed and verified.

## 14. Production safety rules

1. Begin with read-only investigation.
2. Test in a lab or non-production environment.
3. Run `--syntax-check`.
4. Use `--check --diff` where supported.
5. Use `--limit` and verify the selected hosts.
6. Back up important configuration or data before changing it.
7. Require human approval for restarts, package changes, cleanup, deletion, scaling, and configuration deployment.
8. Use least-privilege credentials.
9. Use `serial` for staged production rollout.
10. Set timeouts and stop on validation failure.
11. Keep logs and audit evidence.
12. Verify technical health and application/business health.
13. Keep a tested rollback procedure.
14. Use Git branches and pull-request review for production automation.
15. Never execute unrestricted commands generated directly by an LLM.

## 15. Ansible versus Bash and Python

| Tool | Best fit |
|---|---|
| Ansible | Repeatable configuration and orchestration across many systems |
| Bash | Small Linux-local command sequences and diagnostics |
| Python | APIs, complex logic, data processing, integrations, and custom tooling |

Ansible may call Bash or Python when required, but built-in modules should be preferred for standard system changes.

## 16. Recommended learning order

1. YAML structure and indentation
2. Inventory and host groups
3. Ad-hoc commands
4. Playbooks, plays, tasks, and modules
5. Variables and Jinja
6. Facts and registered output
7. Conditions, loops, and handlers
8. Idempotence and desired state
9. Privilege escalation
10. Templates and configuration validation
11. Roles and collections
12. Vault and secrets
13. Blocks, failure handling, and rollback
14. Check mode, limits, tags, and staged rollout
15. CI linting and pull-request review
16. Linux, Windows, container, monitoring, and remediation labs

## 17. Must-remember facts for a DevOps engineer

- Ansible is declarative where modules describe the desired state, but task order is still important.
- A successful task is not proof that the application is healthy; always verify the outcome.
- `changed` does not necessarily mean success, and `ok` does not necessarily mean the system is correct.
- Shell output should be registered and evaluated, not merely printed.
- Idempotence prevents unnecessary repeated changes.
- Handlers avoid unnecessary service restarts.
- Facts describe the target; variables describe the automation inputs.
- Inventory determines scope, so always verify it before production execution.
- `--limit` is an important safety control.
- Check mode is valuable but not every module supports it completely.
- A service restart can hide the symptom without fixing the root cause.
- Raising CPU, memory, file-descriptor, or timeout limits can hide a leak or design problem.
- Remediation must include investigation, approval, validation, and rollback.
- Secrets belong in Vault or a secret manager, never in Git.
- Small staged batches are safer than changing every production host at once.
- Read the task result fields: `rc`, `stdout`, `stderr`, `changed`, and `failed`.
- Use fully qualified module names.
- Keep playbooks understandable; automation is operational documentation.

## 18. Useful quality tools

```bash
yamllint .
ansible-lint
ansible-playbook playbooks/example.yml --syntax-check
```

Add these checks to CI before allowing changes to merge.

## 19. Definition of done

An automation is complete only when:

- The target and scope are correct.
- Inputs and secrets are handled safely.
- The playbook passes syntax and lint checks.
- It is idempotent where appropriate.
- Failure behavior is known.
- Approval is recorded for state-changing actions.
- Verification confirms the expected result.
- Rollback is available and tested where required.
- Documentation is updated.
