Scheduling (Taints and Labels)
==============================

Motivation
----------

-  In k8s, labels on nodes are used to influence pod scheduling
   (e.g. confine pods to certain nodes)
-  Taints are used to prevent pods from scheduling on nodes unless they
   specifically tolerate a taint
-  We want to be able to confine certain services we provide
   (e.g. Rook and Monitoring) away from the worker nodes

Concept
~~~~~~~

Kubernetes labels and taints are key-value pairs.
Per key and type (label/taint), there can be only one value on a node.
In addition to the key and value, taints also have an ``effect``,
which defines what the taint does.
Typically, it is NoSchedule (which prevents pods from being scheduled
there unless they tolerate that specific taint or the NoSchedule effect in general).

See also:

-  `Kubernetes Documentation: Assigning Pods to Nodes <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/>`__
-  `Kubernetes Documentation: Taints and Tolerations <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/>`__

Assigning labels and taints
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Labels and taints of a node are parsed, processed and passed
to its `kubeadm InitConfiguration <https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/#kubeadm-k8s-io-v1beta3-InitConfiguration>`__
if it is the first control-plane node which initializes the cluster
or to its `kubeadm JoinConfiguration <https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/#kubeadm-k8s-io-v1beta3-JoinConfiguration>`__
if it is a subsequent node which joins the Kubernetes cluster.

Once a node joined the cluster,
its labels and taints do **not** get updated via the LCM anymore.
Once a node joined the cluster,
changing its labels/taints can lead to disruption if the workload
is not immediately reconfigured as well.
A more detailed explanation can be found in the respective
`commit <https://gitlab.com/yaook/k8s/-/commit/4baba5e94b63af34ce44541c69e7c798a673e3bb>`__
which reworked this behavior.

For details on how to configure labels and taints for nodes, please refer to
:ref:`Node-Scheduling: Labels and Taints Configuration <cluster-configuration.node-scheduling-labels-taints-configuration>`

Defining a common Scheduling-Key-Prefix
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is often desirable to use a common prefix
for self-defined labels and taints for consistency.
Yaook/k8s allows to define such a scheduling-key-prefix and then
use it in the label and taint definitions.

Please refer to the
:ref:`Node-Scheduling: Labels and Taints Configuration <cluster-configuration.node-scheduling-labels-taints-configuration>`
for details on how to label and taint nodes with a common scheduling-key-prefix.

Use scheduling keys for Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Scheduling keys control where services may run.
A scheduling key corresponds to both, a node label and to a taint.
It is often desirable to configure a service such
that its workload is spawned on specific nodes.
In especially, it often makes sense to use dedicated monitoring
and storage nodes.

For details on how to use scheduling keys for our supported
storage solution rook, please refer to the
:ref:`Rook Configuration <cluster-configuration.rook-configuration>`

For details on how to use scheduling keys for our supported
monitoring solution, an extended prometheus stack, please refer to the
:ref:`Prometheus-based Monitoring Configuration <cluster-configuration.prometheus-configuration>`
