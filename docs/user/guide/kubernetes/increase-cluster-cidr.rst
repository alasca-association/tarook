Increase K8s cluster CIDR
=========================

.. note::

   Calico IPPools have to be inside the cluster-cidr

.. hint::

   The extended cluster-cidr could be ``10.224.0.0/11`` which contains
   our old cluster-cidr (``10.244.0.0/16``)

Steps to change the cluster-cidr:
---------------------------------

1. Change :ref:`configuration-options.yk8s.kubernetes.network.pod_subnet`
   and apply the k8s-core stage.
   This changes podSubnet in the kubeadm configmap kube-system/kubeadm-config
   and cluster-cidr of the kube-controller-manager on every master node.

2. (If kube-proxy is enabled) Change clusterCIDR in kube-proxy configmap: kube-system/kube-proxy

3. add additional calico ippools:

   .. code:: yaml

      apiVersion: projectcalico.org/v3
      kind: IPPool
      metadata:
        name: additional-ippool-10.224
      spec:
        blockSize: 26
        cidr: 10.224.0.0/16
        ipipMode: Always
        natOutgoing: true
        nodeSelector: all()
        vxlanMode: Never

   => `IPPools have to be applied with calicoctl instead of kubectl <https://github.com/projectcalico/calico/issues/2923>`__.

4. Optional: change pod_subnet in
   ``/var/lib/metal-controller/{CLUSTER}/config`` in the
   metal-controller running in the deploy cluster.

   .. hint::

      This is just for documentation purposes because kubeadm
      picks for new masternodes the range specified in the kubeadm
      configmap
