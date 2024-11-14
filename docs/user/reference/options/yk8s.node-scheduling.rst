.. _configuration-options.yk8s.node-scheduling:

yk8s.node-scheduling
^^^^^^^^^^^^^^^^^^^^


.. note::
  Nodes get their labels and taints during the Kubernetes
  cluster initialization and node-join process.
  Once a node has joined the cluster,
  its labels and taints will **not** get updated anymore.

More details about the labels and taints configuration can be found
:doc:`here </user/explanation/node-scheduling>`.

.. _configuration-options.yk8s.node-scheduling.labels:

``yk8s.node-scheduling.labels``
###############################

Labels are assigned to a node during its initialization/join process only!


**Type:**::

  attribute set of list of non-empty string


**Default:**::

  { }


**Example:**::

  {
    managed-k8s-worker-0 = [
      "''scheduling.mk8s.cloudandheat.com/storage=true"
    ];
    managed-k8s-worker-1 = [
      "''scheduling.mk8s.cloudandheat.com/monitoring=true"
    ];
    managed-k8s-worker-2 = [
      "''scheduling.mk8s.cloudandheat.com/storage=true"
    ];
    managed-k8s-worker-3 = [
      "''scheduling.mk8s.cloudandheat.com/monitoring=true"
    ];
    managed-k8s-worker-4 = [
      "''scheduling.mk8s.cloudandheat.com/storage=true"
    ];
    managed-k8s-worker-5 = [
      "''scheduling.mk8s.cloudandheat.com/monitoring=true"
    ];
  }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/node-scheduling.nix


.. _configuration-options.yk8s.node-scheduling.scheduling_key_prefix:

``yk8s.node-scheduling.scheduling_key_prefix``
##############################################

Scheduling keys control where services may run. A scheduling key corresponds
to both a node label and to a taint. In order for a service to run on a node,
it needs to have that label key. The following defines a prefix for these keys


**Type:**::

  string


**Default:**::

  "scheduling.mk8s.cloudandheat.com"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/node-scheduling.nix


.. _configuration-options.yk8s.node-scheduling.taints:

``yk8s.node-scheduling.taints``
###############################

Taints are assigned to a node during its initialization/join process only!


**Type:**::

  attribute set of list of non-empty string


**Default:**::

  { }


**Example:**::

  {
    managed-k8s-worker-0 = [
      "{{ scheduling_key_prefix }}/storage=true:NoSchedule"
    ];
    managed-k8s-worker-2 = [
      "{{ scheduling_key_prefix }}/storage=true:NoSchedule"
    ];
    managed-k8s-worker-4 = [
      "{{ scheduling_key_prefix }}/storage=true:NoSchedule"
    ];
  }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/node-scheduling.nix

