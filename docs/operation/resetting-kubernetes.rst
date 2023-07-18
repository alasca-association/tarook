Resetting Kubernetes
====================

.. warning::

    **THIS IS EXTREMELY DESTRUCTIVE AND IT WON'T ASK FOR CONFIRMATION**

Use the playbook ``teardown_cluster.yaml`` that runs ``kubeadm reset``
and removes the packages for kubeadm, kubectl and kubelet on all
k8s nodes.
