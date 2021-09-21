# Roles and Taints

## Motivation

- In k8s, labels on nodes are used to influence pod scheduling (e.g. confine pods to certain nodes)
- Taints are used to prevent pods from scheduling on nodes unless they specifically tolerate a taint
- We want to be able to confine certain CPU services we provide (e.g. Rook and Monitoring) away from the worker nodes of the customer

## Implementation

### Concept

Kubernetes labels and taints are a key-value pair. Per key and type (label/taint), there can be only one value on a node. In addition to the key and value, taints also have an `effect`, which defines what the taint does. Typically, it is NoSchedule (which prevents pods from being scheduled there unless they tolerate that specific taint or the NoSchedule effect in general).

See also:

- [Kubernetes Documentation: Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
- [Kubernetes Documentation: Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

We define a key to be used for both a label and a taint to control scheduling. The key is set via the ansible variable `managed_k8s_control_plane_key` and it defaults to `node-restriction.kubernetes.io/cah-managed-k8s-role`. The `node-restriction.kubernetes.io/` prefix prevents the nodes from [overwriting their own role label](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-isolation-restriction).

### Assigning labels and taints

To assign taints and labels to workers via Ansible, host variables need to be set. The `k8s-metadata` role (which is depended on by `connect-k8s-to-openstack`, among others) executes on one of the masters configures the taints and labels for *all* workers.

The host variables which affect the taints and labels are `k8s_node_taints` and `k8s_node_labels` respectively. Both are arrays of strings. The string format is the same as used by the corresponding kubectl commands (`kubectl {taint,label} nodes ...`). Effectively, those strings are passed to that very command.

**Example:** To set the managed kubernetes control plane role to `meta` on a worker, you would write the following into its ansible host vars:

```yaml
k8s_node_labels:
- "{{ managed_k8s_control_plane_key }}=meta"

k8s_node_taints:
- "{{ managed_k8s_control_plane_key }}=meta:PreferNoSchedule"
```

### Configuring scheduling

Those of our services which support scheduling define two variables, one to *select* nodes (via the role label) and one to *tolerate* nodes (via the role taint).

We will use the `rook` deployment as an example. Monitoring works very similarly.

**Example:** Confine Rook services to nodes with the `meta` role:

```yaml
rook_placement_taint:
  key: "{{ managed_k8s_control_plane_key }}"
  value: "meta"
rook_placement_label:
  key: "{{ managed_k8s_control_plane_key }}"
  value: "meta"
```

The `rook_placement_taint` is an object with two properties (`key` and `value`). It defines the key-value pair of the NoSchedule taint the rook control plane pods should tolerate. Note that the rook CSI plugin pods automatically tolerate all NoSchedule taints with the key `managed_k8s_control_plane_key` so that they run on the managed k8s control plane (to make rook storage usable there).

The `rook_placement_label` is also an object with two properties (`key` and `value`). It defines the key-value pair of the label *a node must have* to run rook control plane pods. If `rook_placement_label` is set, it is *required* that at least three nodes in a deployment have this label to make rook work; otherwise, it cannot schedule three independent mons and will fail.

Similarly, you can configure `monitoring_placement_{taint,label}` to control scheduling of the Monitoring control plane (prometheus, thanos, grafana and alertmanager). Like with the CSI plugins of Rook, the node-exporter tolerates the managed kubernetes control plane taint automatically to run everywhere for monitoring purposes.
