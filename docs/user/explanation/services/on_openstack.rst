Connect to Openstack
====================

The ``connect_k8s_to_openstack_v2`` role connects kubernetes
with the underlying openstack. For this it deploys several resources.

Legacy deployment
-----------------

Before the introduction of the community helm chart,
the `openstack-cloud-controller-manager` and the
`cinder-csi`-plugins were deployed via manifests.

If you want to trigger the migration manually,
you have to set:

.. code:: toml

   [miscellaneous]
   openstack_connect_use_helm = true

``connect_k8s_to_openstack_v1`` will be dropped soon.
