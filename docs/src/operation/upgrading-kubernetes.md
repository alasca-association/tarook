# Upgrading Kubernetes

---

**Table of Contents:**

- [Upgrading Kubernetes](#upgrading-kubernetes)
  - [Upgrade implications / disruptions](#upgrade-implications-disruptions)
  - [General procedure](#general-procedure)
  - [Upgrading specific versions](#upgrading-specific-versions)
    - [Upgrading to 1.18.x (from 1.17.x or 1.18.x)](#upgrading-to-118x-from-117x-or-118x)
  - [Skip Intermittent Cluster Health Verification](#skip-intermittent-cluster-health-verification)
  - [Kubernetes Component Versioning](#kubernetes-component-versioning)
    - [General Information](#general-information)
    - [Calico](#calico)
      - [Manually Upgrade Calico](#manually-upgrade-calico)

---

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

## Kubernetes Component Versioning

### General Information

In general, we're mapping the versions of components which are essential for Kubernetes to properly
work to the Kubernetes version in the [`k8s-config` role](https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/k8s-config/defaults/main.yaml#L31).

All versions of non-essential components are not mapped to the Kubernetes version, i.e. all
components/services above the Kubernetes layer itself ("stage 3") but on the service layer ("stage4").

### Calico

The calico version is mapped to the Kubernetes version and calico is updated to the mapped version
during Kubernetes upgrades.
However, it is possible to manually update calico to another version.

#### Manually Upgrade Calico

The calico version can be manually set via the [`calico_custom_version`](../usage/cluster-configuration.md#network-configuration) variable in the
`[kubernetes.network]` section of cluster-specific your `config/config.toml`.

You have to choose one of the following:

* `v3.17.1`
* `v3.19.0`
* `v3.21.6`
* `v3.24.5`

After updating that variable, you can then update calico by executing the following.
Note that this is a (slightly) disruptive action:

```shell
MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff -t calico" bash managed-k8s/actions/apply-stage3.sh
```

Optionally, you can verify the calico functionality afterwards by triggering the test role:

```
AFLAGS="--diff -t check-calico" bash managed-k8s/actions/test.sh
```
