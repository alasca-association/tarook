Terraform state migrations
==========================

Sometimes Terraform modules have to be reworked in an incompatible manner.
In such cases, a state migration is necessary prior to continue using the LCM.
:ref:`configuration-options.yk8s.terraform.modules` provides a mechanism to automate renames.
Rename the resource and then set the attribute ``_import_from`` to the old path of the resource.

Example:

.. code:: nix

      resource.openstack_networking_router_interface_v2.cluster_router_iface = {
        _import_from = "openstack_networking_router_interface_v2.cluster_router_iface[0]";
        router_id = yk8s-lib.tfRef "openstack_networking_router_v2.cluster_router.id";
        subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";
      };

These migrations are picked up by the permanent release-migration script ``a-10-terraform-state-migrations.sh``.

``_import_from`` _should_ then be removed for the next major release.
