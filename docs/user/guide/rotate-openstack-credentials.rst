Rotate OpenStack Credentials
============================

The following document describes the necessary actions
that must be taken LCM-wise after an OpenStack credential rotation.

1. Change the OpenStack credentials (how to do that is out of scope).
2. Trigger rotation of managed components

   .. tabs::

      .. tab:: ch-k8s-lbaas disabled

         Immediately afterwards renew the OpenStack connection of the Kubernetes cluster.
         This will update the ``kube-system/cloud-config`` secret
         and restart the cloud-controller-manager, csi-cinder-controllerplugin and
         csi-cinder-nodeplugin in the ``kube-system`` namespace.

         .. code:: console

            $ AFLAGS="--diff -t connect-k8s-to-openstack" bash managed-k8s/actions/apply-k8s-supplements.sh

      .. tab:: ch-k8s-lbaas enabled

         Immediately afterwards renew the OpenStack connection of the Kubernetes cluster.
         This will update the ``kube-system/cloud-config`` secret
         and restart the cloud-controller-manager, csi-cinder-controllerplugin and
         csi-cinder-nodeplugin in the ``kube-system`` namespace.
         It will also update the ``kube-system/ch-k8s-lbaas-controller-config`` secret and restart
         the ch-k8s-lbaas-controller in the ``kube-system`` namespace.

         .. code:: console

            $ AFLAGS="--diff -t connect-k8s-to-openstack,ch-k8s-lbaas" bash managed-k8s/actions/apply-k8s-supplements.sh

3. Verify that everything is able to come up after it has been restarted.
4. Check which Pods besides the above mentioned have mounted the ``kube-system/cloud-config`` secret:

   .. code:: console

      $ kubectl get pod -A -o json | jq '.items[] | select(.spec.volumes[].secret.secretName=="cloud-config") | "\(.metadata.namespace)/\(.metadata.name)\n"'

5. Check which Pods are referencing the ``kube-system/cloud-config`` secret in their env:

   .. code:: console

      $ kubectl get pod -A -o json | jq '.items[] | select(.spec.containers[].env[]?.valueFrom.secretKeyRef.name=="cloud-config") | "\(.metadata.namespace)/\(.metadata.name)\n"'

6. Figure out how these Pods are controlled and (rollout) restart them.
