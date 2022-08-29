# Upgrading Kubernetes

## Upgrade implications / disruptions

- All pods will be rescheduled at least once, sometimes more often
- All pods without a controller will be deleted
- Data in emptyDir volumes will be lost
- (if enabled) Ceph storage will be blocking/unavailable for the duration of the
  upgrade

## General procedure

1. Agree on a time window with the customer. Make sure they are aware of the
   disruptions.

2. Ensure that the cluster is healthy. All pods managed by us should be
   Running or Completed. Pods managed by the customer should also be in such
   states; but if they are not, there’s nothing we can do about it.

3. Execute the upgrade. See below for version-specific information.

## Upgrading specific versions

### Upgrading to 1.18.x (from 1.17.x or 1.18.x)

1. Pick the version to upgrade to. Ideally, this is the most recent 1.18.x
   release. In this example, we’ll use 1.18.1.

2. Execute the upgrade playbook from within the cluster repository:

   ```console
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.18.1
   ```

3. Once the upgrade executed successfully, update your `config.toml` to point to
   the new k8s version:

   ```toml
   [kubernetes]
   version="1.18.1"
   ```

## Skip Intermittent Cluster Health Verification

Simply said, during a Kubernetes upgrade, all nodes get tainted, upgraded and uncordoned.
The nodes do get processed quickly one after another.
In between the node upgrades, the `cluster_health_verification`-role is executed.
This role contains tasks to verify the cluster has converged before tainting the next node.

These intermediate tasks can be circumvented by passing `-s` to the [`upgrade.sh'-script](../operation/actions-references.md#upgradesh).
The flag has to be passed between the script path and the target version.

```console
# Triggering a Kubernetes upgrade and skip health verification tasks
$ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh -s 1.22.11
```
