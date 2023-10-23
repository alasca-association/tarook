Actions References
==================

The ``managed-k8s`` submodule provides the following ready-to-use action
scripts to work with the cluster repository. The scripts extensively
rely on environment variables. See the
:doc:`Environment Variables Reference </usage/environmental-variables>`
for details.

-  :ref:`init.sh <actions-references.initsh>`
-  :ref:`apply.sh <actions-references.applysh>`
-  :ref:`apply-terraform.sh <actions-references.apply-terraformsh>`
-  :ref:`apply-stage2.sh <actions-references.apply-stage2sh>`
-  :ref:`apply-stage3.sh <actions-references.apply-stage3sh>`
-  :ref:`apply-stage4.sh <actions-references.apply-stage4sh>`
-  :ref:`apply-stage5.sh <actions-references.apply-stage5sh>`
-  :ref:`apply-custom.sh <actions-references.apply-customsh>`
-  :ref:`test.sh <actions-references.testsh>`

Additional operating scripts:

- :ref:`system_update_nodes.sh<actions-references.system_update_nodessh>`
- :ref:`destroy.sh<actions-references.destroysh>`
- :ref:`wg-up.sh<actions-references.wg-upsh>`
- :ref:`manage_roles.py<actions-references.manage_rolespy>`
- :ref:`manual-terraform.sh<actions-references.manual-terraformsh>`
- :ref:`Examples <actions-references.examples>`
- :ref:`update_inventory.py<actions-references.update_inventorypy>`
- :ref:`upgrade.sh<actions-references.upgradesh>`
- :ref:`lib.sh<actions-references.libsh>`

.. _actions-references.initsh:

``init.sh``
-----------

The ``init.sh``-script is used for the
:doc:`Cluster Repository Initialization </usage/initialization>`.
Before executing this script you **must** have configured your
:doc:`environment variables </usage/environmental-variables>`.
The script will create the basic cluster repository structure as
described :doc:`here </concepts/cluster-repository>`. Except in very
rare cases where a new feature requires it, you’ll need and should
execute this script only once.

.. _actions-references.applysh:

``apply.sh``
------------

``managed-k8s/actions/apply.sh`` is a wrapper script which can be used
to create a yk8s on top of OpenStack.

The script triggers the execution of the following scripts:

-  :ref:`apply-terraform.sh <actions-references.apply-terraformsh>`
-  :ref:`apply-stage2.sh <actions-references.apply-stage2sh>`
-  :ref:`apply-stage3.sh <actions-references.apply-stage3sh>`
-  :ref:`apply-stage4.sh <actions-references.apply-stage4sh>`
-  :ref:`apply-stage5.sh <actions-references.apply-stage5sh>`
-  :ref:`apply-custom.sh <actions-references.apply-customsh>`
-  :ref:`test.sh <actions-references.testsh>`

.. _actions-references.apply-terraformsh:

``apply-terraform.sh``
----------------------

.. figure:: /img/apply-terraform.svg
   :scale: 80%
   :alt: Apply Terraform Script Visualization
   :align: center

|

The ``apply-terraform.sh``-script creates and updates the underlying
cluster platform infrastructure (sometimes also called harbour
infrastructure layer) as defined by the
:doc:`configuration </usage/cluster-configuration>`. It also creates
and updates the inventory files for ansible (``inventory/*/hosts``) and
creates some variables in the inventory (all created files have the
``terraform_`` prefix).

.. _actions-references.apply-stage2sh:

``apply-stage2.sh``
-------------------

.. figure:: /img/apply-stage2.svg
   :scale: 80%
   :alt: Apply Stage 2 Script Visualization
   :align: center

|

The ``apply-stage2.sh``-script can be used to trigger the frontend
preparation. This script triggers an Ansible playbook which installs and
prepares the frontend nodes, including rolling out all users, setting up
the basic infrastructure for C&H LBaaS and configuring wireguard.

.. _actions-references.apply-stage3sh:

``apply-stage3.sh``
-------------------

.. figure:: /img/apply-stage3.svg
   :scale: 80%
   :alt: Apply Stage 3 Script Visualization
   :align: center

|

This installs the Kubernetes worker and master nodes, including rolling
out all users, installing Kubernetes itself, deploying Rook, Prometheus
etc., and configuring C&H LBaaS (also on the frontend nodes) if it is
enabled.


.. _actions-references.apply-stage4sh:

``apply-stage4.sh``
-------------------

.. figure:: /img/apply-stage4.svg
   :scale: 80%
   :alt: Apply Stage 4 Script Visualization
   :align: center

|

.. todo::

   add details

.. _actions-references.apply-stage5sh:

``apply-stage5.sh``
-------------------

.. figure:: /img/apply-stage5.svg
   :scale: 80%
   :alt: Apply Stage 5 Script Visualization
   :align: center

|

.. todo::

   add details

.. _actions-references.apply-customsh:

``apply-custom.sh``
-------------------

.. figure:: /img/apply-custom.svg
   :scale: 80%
   :alt: Apply Custom Script Visualization
   :align: center

|

.. todo::

    add details

.. _actions-references.testsh:

``test.sh``
-----------

This runs the cluster test suite. It ensures basic functionality:

-  Starting a pod & service
-  Cinder volume block storage
-  Rook ceph block storage (if enabled)
-  Rook ceph shared filesystem storage (if enabled)
-  C&H LBaaS (if enabled)
-  Pod security policies (if enabled)
-  Network policies (if enabled)
-  Monitoring (if enabled)

.. _actions-references.system_update_nodessh:

``system_update_nodes.sh``
--------------------------

This triggers system updates of the host nodes (harbour infrastructure
layer). That includes updates of the frontend nodes and as well as
Kubernetes nodes. As this may be a disruptive action, you have to
explicitly allow system updates by setting
``MANAGED_K8S_RELEASE_THE_KRAKEN`` (see
:ref:`Environment Variables <environmental-variables.behavior-altering-variables>`.
Nodes will get updated one after another if they are already
initialized. Between the node updates, it is verified that the cluster
is healthy. These verification checks can be skipped by passing ``-s``.

.. code:: console

   # Trigger system updates of nodes
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/system_update_nodes.sh [-s]

.. _actions-references.destroysh:

``destroy.sh``
--------------

Destroy the entire cluster and all of its data.

This is, obviously, destructive. Don’t run light-heartedly.

.. _actions-references.wg-upsh:

``wg-up.sh``
------------

When the Wireguard tunnel needs to be up, it is automatically setup by
all ``apply-*.sh``-scripts.

Bring up the WireGuard VPN to the cluster.

It tries to be smart about not doing anything stupid and ensuring that
you’re really connected to the correct cluster.

.. _actions-references.manage_rolespy:

``manage_roles.py``
-------------------

This Python script should be used to create new Ansible roles and update
and extend the meta information of existing ones. The script can create
and update roles with a minimal skeleton and an extended one
(``--full``).

For further information on Ansible meta information take a look
`here <https://galaxy.ansible.com/docs/contributing/creating_role.html#role-metadata>`__.

::

   usage: manage_roles.py [-h] {init,update} ...

   positional arguments:
     {init,update}  Desired action to perform
       init         Initialize the skeleton for a new ansible role
       update       Update the existing ansible role. This action only updates the meta/main.yaml of the existing ansible role. If you want to create missing skeleton directory structure use `--create-missing` argument.

   optional arguments:
     -h, --help     show this help message and exit

.. _actions-references.manual-terraformsh:

``manual-terraform.sh``
-----------------------

This is a thin wrapper around Terraform. The arguments are passed on to
Terraform, and the environment for it is set to use the same module and
state as when run from ``apply-terraform.sh``.

This is useful for operational interventions, debugging and development
work (e.g. to inspect the state or to taint a resource in order to have
it rebuilt when running ``apply.sh``).

Example usage:

.. code:: console

   $ ./managed-k8s/actions/manual-terraform.sh taint 'openstack_compute_instance_v2.master["managed-k8s-master-1"]'

.. _actions-references.examples:

Examples
~~~~~~~~

Creating a new role into the k8s-base directory:

.. code:: console

   $ python3 managed-k8s/actions/manage_roles.py init "ROLE_NAME" --path managed-k8s/k8s-base/roles

Updating the authors for all KSL roles:

.. code:: console

   $ python3 actions/manage_roles.py update '*' --path k8s-service-layer/roles --author "AUTHORS"

.. _actions-references.update_inventorypy:

``update_inventory.py``
-----------------------

.. figure:: /img/update-inventory.svg
   :scale: 80%
   :alt: Update Inventory Script Visualization
   :align: center

|

The inventory updater is triggered automatically in advance of each
action script. It cleans up the inventory and ensures the latest
variable/value pairs from your configuration file are used.

.. _actions-references.upgradesh:

``upgrade.sh``
--------------

This script can be used to trigger a Kubernetes upgrade. More details
about that can be found :doc:`here </operation/upgrading-kubernetes>`.

.. _actions-references.libsh:

``lib.sh``
----------

The ``lib.sh`` is included by other action scripts and defines commonly
used variables and function definitions.
