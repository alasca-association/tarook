Cluster
=======

One instance of Tarook builds and manages a single Kubernetes cluster.


.. _cluster.node-labeling:

Node labeling
-------------

Tarook ensures that certain labels are attached to Kubernetes nodes:

- ``node-role.kubernetes.io/control-plane=`` to control plane nodes
- ``node-role.kubernetes.io/worker=`` to worker nodes
- ``k8s.yaook.cloud/gpu-node=true`` to worker nodes with GPU
