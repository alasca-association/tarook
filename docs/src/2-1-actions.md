# Actions Reference

<!-- TODO: needs updating with current LCM -->

The `managed-k8s` submodule provides the following actions to work with the
cluster repository. All paths are relative to the cluster repository.

The scripts extensively rely on environment variables. See the
[Environment Variables Reference](./2-1-envvars.md) for details.

- on changes: `run python3 managed-k8s/jenkins/toml_helper.py`
- run `python3 <path-to-managed-k8s>/jenkins/toml_helper.py`
- alternatively, run `<path-to-managed-k8s>/actions/apply.sh` to use own changes

- `managed-k8s/actions/apply.sh`: Runs terraform, stage2, stage3 and test in
  that order.

  See below for the individual steps.

- `managed-k8s/actions/apply-terraform.sh`: Run terraform

  This creates/updates the cluster platform infrastructure as defined by the
  configuration and the code in `managed-k8s`. It also updates the inventory
  files for ansible (`inventory/*/hosts`).

- `managed-k8s/actions/apply-stage2.sh`: Run ansible on the gateway nodes

  This installs the gateway nodes, including rolling out all users, setting
  up the basic infrastructure for C&H LBaaS and configuring wireguard.

- `managed-k8s/actions/apply-stage3.sh`: Run ansible on all nodes

  This installs the Kubernetes worker and master nodes, including rolling out
  all users, installing Kubernetes itself, deploying Rook, Prometheus etc.,
  and configuring C&H LBaaS (also on the gateways) if it is enabled.

  Also runs `managed-k8s/actions/wg-up.sh` (see below).

- `managed-k8s/actions/test.sh`: Run cluster tests

  This runs the cluster test suite. It ensures basic functionality:

  - Starting a pod & service
  - Cinder volume block storage
  - Rook ceph block storage (if enabled)
  - Rook ceph shared filesystem storage (if enabled)
  - C&H LBaaS (if enabled)
  - Pod security policies (if enabled)
  - Network policies (if enabled)
  - Monitoring (if enabled)

  Also runs `managed-k8s/actions/wg-up.sh` (see below).

- `managed-k8s/actions/wg-up.sh`: Bring up the WireGuard VPN to the cluster.

  It tries to be smart about not doing anything stupid and ensuring that you’re
  really connected to the correct cluster.

- `managed-k8s/actions/destroy.sh`: Destroy the entire cluster and all of its
  data.

  This is, obviously, destructive. Don’t run light-heartedly.
