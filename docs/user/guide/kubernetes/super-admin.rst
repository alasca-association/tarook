Generate a super admin kubeconfig
=================================

Starting with Kubernetes v1.29, the usual admin kubeconfigs
are bound to to the ``kubeadm:cluster-admins`` RBAC group.

To generate a super admin kubeconfig which can bypass RBAC,
you can execute the following:

.. code:: console

  $ ./managed-k8s/actions/k8s-login.sh -s

Please also refer to
`kubeadm implementation details <https://kubernetes.io/docs/reference/setup-tools/kubeadm/implementation-details/>`_
