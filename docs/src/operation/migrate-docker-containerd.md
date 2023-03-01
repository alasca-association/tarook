# Migrate CRI from docker to containerd

---

**Table of Contents:**

- [Migrate CRI from docker to containerd](#migrate-cri-from-docker-to-containerd)
  - [Procedure Description](#procedure-description)
  - [Skip intermediate Cluster Health Verification](#skip-intermediate-cluster-health-verification)

---

> **NOTE:** You must migrate to containerd **prior** to upgrading to Kubernetes v1.24 as Kubernetes [dropped support for dockershim](https://kubernetes.io/blog/2022/03/31/ready-for-dockershim-removal/).

---

The process of changing the CRI from docker to containerd is well documented in the official Kubernetes documentation: [Changing the Container Runtime on a Node from Docker Engine to containerd](https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/).

## Procedure Description

This section gives a brief overview about which steps have been implemented to migrate from docker to containerd in the respective [action script](./actions-references.md#migrate-docker-containerdsh).

First, connectivity to the nodes is established.
After that, each node gets processed in serial.
It is ensured that the container runtime is [configured correctly](./../usage/cluster-configuration.md#miscellaneous-configuration).

For each node, the following steps are taken:

* Check if the node already uses containerd as container runtime, all following steps are skipped if that's the case.
* Ensure the cluster is healthy. This can be [skipped](#skip-intermediate-cluster-health-verification).
* Drain the node
* System update the node
  * As the node is drained, this is a good point in time to throw in a system update
* Stop `kubelet`
* Stop and disable docker
* Install containerd
* Configure `kubelet` to use containerd as CRI.
* Restart `kubelet`
* Patch the respective node annotation.
  * As we're using `kubeadm` to build our Kubernetes cluster and `kubeadm` annotates the node with the respective container runtime, we need to patch that annotation.
* Verify that the container runtime of the node is containerd now.
* Remove docker engine from the node.
* Restart `kubelet`.
  * Another restart of `kubelet` is needed after removing the docker engine.
* Uncordon the node

After each node has been processed and the playbook finished successfully, one **must** change the [container runtime variable](./../usage/cluster-configuration.md#miscellaneous-configuration) in its `config/config.toml` to `containerd` before continuing with further operations.

## Skip intermediate Cluster Health Verification

Obviously, changing the container runtime for a node is considered disruptive.
Nodes get migrated in serial (one after another).
In-between the single migration of each node , the `cluster_health_verification`-role is executed.
This role contains tasks to verify the cluster has converged before tainting & draining the next node.

These intermediate tasks can be circumvented by passing `-s` to the [`upgrade.sh'-script](../operation/actions-references.md#upgradesh).
The flag has to be passed between the script path and the target version.
Skipping the health verification tasks is not recommended.

```console
MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/migrate-docker-containerd.sh [-s]
```
