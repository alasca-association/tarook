.. _configuration-options.yk8s.node-scheduling:

yk8s.node-scheduling
^^^^^^^^^^^^^^^^^^^^


.. note::
  Nodes get their labels and taints during LCM rollout.
  Once a node has joined the cluster,
  its labels and taints can only be changed or new ones be added.
  Removal is currently not supported.

More details about the labels and taints configuration can be found
:doc:`here </user/explanation/node-scheduling>`.

.. _configuration-options.yk8s.node-scheduling.labels:

``yk8s.node-scheduling.labels``
###############################

Labels are assigned to a node during LCM rollout only!

Can be set to ``null`` in order to remove the label.


**Type:**::

  attribute set of ((list of Kubernetes label string) or attribute set of (null or Kubernetes label value))


**Default:**::

  { }


**Example:**::

  {
    managed-k8s-worker-0 = {
      "example.org/monitoring" = "true";
      "example.org/storage" = "true";
    };
    managed-k8s-worker-1 = [
      "example.org/storage=true"
      "example.org/monitoring=true"
    ];
    managed-k8s-worker-2 = {
      "example.org/monitoring" = null;
      "example.org/storage" = null;
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/node-scheduling.nix


.. _configuration-options.yk8s.node-scheduling.scheduling_key_prefix:

``yk8s.node-scheduling.scheduling_key_prefix``
##############################################

.. note:: DEPRECATED

   This option is going to be removed. Please use Nix's let expression instead.

Scheduling keys control where services may run. A scheduling key corresponds
to both a node label and to a taint. In order for a service to run on a node,
it needs to have that label key. The following defines a prefix for these keys


**Type:**::

  string


**Default:**::

  "scheduling.mk8s.cloudandheat.com"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/node-scheduling.nix


.. _configuration-options.yk8s.node-scheduling.taints:

``yk8s.node-scheduling.taints``
###############################

Taints are assigned to a node during LCM rollout only!

Can be set to ``null`` in order to remove the taint.


**Type:**::

  attribute set of ((list of Kubernetes taint string) or attribute set of (null or (submodule)))


**Default:**::

  { }


**Example:**::

  {
    managed-k8s-worker-0 = {
      "examply.org/storage" = {
        effect = "NoSchedule";
        value = "true";
      };
    };
    managed-k8s-worker-2 = [
      "example.org/storage=true:NoSchedule"
    ];
    managed-k8s-worker-4 = {
      "examply.org/storage" = null;
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/node-scheduling.nix

