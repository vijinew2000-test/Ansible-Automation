# AIOps Use Cases

This folder contains Ansible use cases that combine operational signals, decision logic, guarded remediation, and verification.

## Included use cases

- [Network latency detection and automatic failover](network-latency-automatic-failover/README.md)

## Safety model

AIOps automation should:

1. Collect evidence before changing state.
2. Confirm an anomaly to avoid reacting to a transient spike.
3. Validate the remediation target.
4. Stop safely when no healthy target is available.
5. Limit changes to an explicitly approved mechanism.
6. Record the decision and verify the outcome.
7. Keep credentials and environment-specific values in inventory, Unity, Vault, or an approved secret manager.
