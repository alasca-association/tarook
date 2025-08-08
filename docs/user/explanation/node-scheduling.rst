Scheduling (Taints and Labels)
==============================

Motivation
----------

-  In K8s, labels on nodes are used to influence pod scheduling
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

.. note::

   Some node labels are managed by Tarook.
   Expect your changes to such labels to be overwritten.
   Please refer to
   :ref:`the respective documentation <cluster.node-labeling>` for details.

Labels and taints of a node are parsed, processed and assigned
during LCM rollout after the node joined the cluster.

The LCM does not support removal of labels/taints
for nodes that already joined the cluster.
Changing node labels/taints can lead to disruption if the workload
is not immediately reconfigured as well.
A more detailed explanation can be found in the respective
`commit <https://gitlab.com/alasca.cloud/tarook/tarook/-/commit/4baba5e94b63af34ce44541c69e7c798a673e3bb>`__
which reworked this behavior.

For details on how to configure labels and taints for nodes, please refer to
:ref:`Node-Scheduling: Labels and Taints Configuration <configuration-options.yk8s.node-scheduling>`

Defining a common Scheduling-Key-Prefix
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is often desirable to use a common prefix
for self-defined labels and taints for consistency.
Tarook allows to define such a scheduling-key-prefix and then
use it in the label and taint definitions.

Please refer to the
:ref:`Node-Scheduling: Labels and Taints Configuration <configuration-options.yk8s.node-scheduling>`
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
:ref:`Rook Configuration <configuration-options.yk8s.k8s-service-layer.rook>`

For details on how to use scheduling keys for our supported
monitoring solution, an extended prometheus stack, please refer to the
:ref:`Prometheus-based Monitoring Configuration <configuration-options.yk8s.k8s-service-layer.prometheus>`
