# Network Latency Detection and Automatic Failover

## Purpose

`network-latency-automatic-failover.yml` measures latency to a primary destination, waits and confirms a persistent anomaly, validates an alternate destination, and records which server should be active.

## Workflow

1. Validate the primary and alternate server inputs.
2. Measure the primary server's average ICMP round-trip time.
3. Compare the result with `baseline_ms`.
4. Wait `confirmation_wait` seconds and test the primary again when abnormal.
5. Test the alternate server before selecting it.
6. Stop without writing a failover destination if the alternate is unavailable.
7. Write the selected alternate to `/opt/network_active_server.conf`.
8. Append the decision to `/var/log/network_latency_failover.log`.

## Important scope

This playbook writes:

```text
ACTIVE_SERVER=<selected-server>
```

It does **not** directly change NGINX, DNS, a load balancer, routing, or application traffic. A reviewed downstream component must consume `/opt/network_active_server.conf` for traffic to move.

The file is changed only when confirmed primary latency requires failover and the alternate returns a valid RTT. When the primary is healthy, the play reports that it remains active without rewriting the destination file.

## Required inputs

Supply these through inventory, Unity, or protected extra variables:

- `primary_server`
- `alternate_server`

Do not commit environment addresses or credentials to Git.

Example:

```bash
ansible-playbook -i inventories/lab/hosts.yml \
  use-cases/aiops/network-latency-automatic-failover/network-latency-automatic-failover.yml \
  --limit approved-host \
  --extra-vars "primary_server=PRIMARY_ADDRESS alternate_server=ALTERNATE_ADDRESS"
```

## Requirements

- Linux managed host with `ping`, Bash, and `awk`.
- Privilege escalation because the play writes under `/opt` and `/var/log`.
- Network policy permitting ICMP to both destinations.
- A lab-calibrated `baseline_ms`; the included `0.30` ms value must not be treated as a universal production threshold.

## Safety notes

- Test in a lab first.
- Confirm that ICMP latency represents the service path being protected.
- A successful ping does not prove that the application port or business service is healthy.
- Production failover should normally validate the actual service protocol as well as network reachability.
- Review how the downstream traffic component consumes the active-server file before enabling automated remediation.
