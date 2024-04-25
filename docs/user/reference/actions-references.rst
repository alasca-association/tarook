Actions References
==================

The ``managed-k8s`` submodule provides the following ready-to-use action
scripts to work with the cluster repository. The scripts extensively
rely on environment variables. See the
:doc:`Environment Variables Reference </user/reference/environmental-variables>`
for details.

Overview
--------

**Main action scripts**:

-  :ref:`init-cluster-repo.sh <actions-references.init-cluster-reposh>`
-  :ref:`apply-all.sh <actions-references.apply-allsh>`
-  :ref:`apply-custom.sh <actions-references.apply-customsh>`
-  :ref:`apply-k8s-core.sh <actions-references.apply-k8s-coresh>`
-  :ref:`apply-k8s-supplements.sh <actions-references.apply-k8s-supplementssh>`
-  :ref:`apply-prepare-gw.sh <actions-references.apply-prepare-gwsh>`
-  :ref:`apply-terraform.sh <actions-references.apply-terraformsh>`
-  :ref:`test.sh <actions-references.testsh>`

**Additional operating scripts**:

- :ref:`destroy.sh<actions-references.destroysh>`
- :ref:`migrate-cluster-repo.sh<actions-references.migrate-cluster-reposh>`
- :ref:`update-frontend-nodes.sh<actions-references.update-frontend-nodessh>`
- :ref:`update-kubernetes-nodes.sh<actions-references.update-kubernetes-nodessh>`
- :ref:`upgrade.sh<actions-references.upgradesh>`
- :ref:`verify-cluster-health.sh<actions-references.verify-cluster-healthsh>`

**Additional development scripts**:

- :ref:`manage_roles.py<actions-references.manage_rolespy>`

**Additional helper scripts**:

- :ref:`lib.sh<actions-references.libsh>`
- :ref:`manual-terraform.sh<actions-references.manual-terraformsh>`
- :ref:`wg-up.sh<actions-references.wg-upsh>`
- :ref:`update_inventory.py<actions-references.update_inventorypy>`

.. _actions-references.init-cluster-reposh:

``init-cluster-repo.sh``
------------------------

The ``init-cluster-repo.sh``-script is used for the
:doc:`Cluster Repository Initialization </user/guide/initialization>`.
Before executing this script you **must** have configured your
:doc:`environment variables </user/reference/environmental-variables>`.
The script will create the basic cluster repository structure as
described :doc:`here </user/reference/cluster-repository>`. Except in very
rare cases where a new feature requires it, you’ll need and should
execute this script only once.

Apply Scripts
-------------

.. _actions-references.apply-script-general:

General
~~~~~~~

.. figure:: /img/apply-script.drawio.svg
   :scale: 80%
   :alt: Apply Custom Script Visualization
   :align: center

   High-level overview how the ``apply-*.sh`` action scripts work in general.

|

The figure above depicts how action scripts work in general.
An action script gathers and prepares all the required prerequisites
to run a specific Ansible playbook.
In particular this means that the inventory is updated,
the kubeconfig is loaded and the paths to the Ansible roles
of the k8s-core and k8s-supplements components are prepared.
In the case of running on OpenStack with gateway nodes in front,
the action script also ensures that the Wireguard tunnel is established.
The action script then invokes an Ansible playbook passing all the
required surroundings to the invocation.

The triggered Ansible playbook can then serve different purposes
like initialization of the Kubernetes cluster,
installing additional services like a monitoring stack
or upgrading an existing Kubernetes cluster.
The playbooks may interact directly with the target nodes
or with the Kubernetes API.

As we're using Hashicorp Vault as secrets management backend,
the Ansible playbook as well as system components of the cluster itself like
the Kubernetes nodes do interact with the configured Hashicorp Vault instance
to manage credentials and secrets.

.. _actions-references.apply-allsh:

``apply-all.sh``
~~~~~~~~~~~~~~~~

The ``apply-all.sh``-script is a wrapper script which can be used
to create a yaook/k8s-cluster on top of OpenStack.

In general, if you do not want to trigger action scripts in a more fine
grained manner, this is the script to keep the cluster in sync.

The script updates the Ansible inventory,
installs the Ansible galaxy requirements
and applies the whole LCM by
triggering the following other action scripts:

- :ref:`apply-terraform.sh <actions-references.apply-terraformsh>`
- :ref:`apply-prepare-gw.sh <actions-references.apply-prepare-gwsh>`
- :ref:`apply-k8s-supplements.sh <actions-references.apply-k8s-supplementssh>`
- :ref:`apply-custom.sh <actions-references.apply-customsh>`

.. _actions-references.apply-customsh:

``apply-custom.sh``
~~~~~~~~~~~~~~~~~~~

The ``apply-custom.sh``-script triggers the
customization playbook.
It is enabled by default.
You can :ref:`disable the customization<abstraction-layers.customization>`
if not needed.


.. _actions-references.apply-k8s-coresh:

``apply-k8s-core.sh``
~~~~~~~~~~~~~~~~~~~~~

The ``apply-k8s-core.sh``-script allows to trigger
the k8s-core functionality in whole by invoking
its ``install-all.yaml`` playbook.

.. _actions-references.apply-k8s-supplementssh:

``apply-k8s-supplements.sh``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``apply-k8s-supplements.sh``-script allows to trigger
the k8s-supplements functionality in whole by invoking
its ``install-all.yaml`` playbook.
This playbook takes the necessary preparations
for the cluster if running on top of OpenStack
and then invokes the k8s-core ``install-all.yaml`` playbook.
After the Kubernetes cluster is created,
it adds necessary and optional surroundings to the cluster.

This script contains the following functionality as subsets:

- :ref:`apply-prepare-gw.sh <actions-references.apply-prepare-gwsh>`
- :ref:`apply-k8s-core.sh <actions-references.apply-k8s-coresh>`

.. _actions-references.apply-prepare-gwsh:

``apply-prepare-gw.sh``
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``apply-prepare-gw.sh``-script takes the necessary
preparations to deploy a yaook-k8s-cluster on top of OpenStack
which covers bootstrapping, preparation and configuration
of the gateway nodes in front of the Kubernetes cluster.

.. _actions-references.apply-terraformsh:

``apply-terraform.sh``
~~~~~~~~~~~~~~~~~~~~~~

.. figure:: /img/apply-terraform.svg
   :scale: 80%
   :alt: Apply Terraform Script Visualization
   :align: center

|

The ``apply-terraform.sh``-script creates and updates the underlying
harbour infrastructure layer as defined by the
:doc:`configuration </user/reference/cluster-configuration>`. It also creates
and updates the inventory files for ansible (``inventory/*/hosts``) and
creates some variables in the inventory (all files created have the
``terraform_`` prefix).

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

.. _actions-references.destroysh:

``destroy.sh``
--------------

Destroy the entire cluster and all of its data.

This is, obviously, destructive. Don’t run light-heartedly.

.. _actions-references.migrate-cluster-reposh:

``migrate-cluster-repo.sh``
---------------------------

Migrate an existing cluster repository which has been created
`pre-core-split <https://gitlab.com/yaook/k8s/-/merge_requests/823>`__ to the new cluster repository structure.
This script is idempotent.

.. _actions-references.update-frontend-nodessh:

``update-frontend-nodes.sh``
----------------------------

This triggers system updates of the frontend nodes
(part of the harbour infrastructure layer).
As this may be a disruptive action, you have to
explicitly allow system updates by setting
``MANAGED_K8S_RELEASE_THE_KRAKEN`` (see
:ref:`Environment Variables <environmental-variables.behavior-altering-variables>`.
Nodes will get updated one after another if they are already
initialized. Between the node updates, it is verified that the cluster
is healthy. These verification checks can be skipped by passing ``-s``.

.. code:: console

   $ # Trigger system updates of nodes
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/update-frontend-nodes.sh [-s]

.. _actions-references.update-kubernetes-nodessh:

``update-kubernetes-nodes.sh``
------------------------------

This triggers system updates of the Kubernetes nodes
(part of the harbour infrastructure layer).
As this may be a disruptive action, you have to
explicitly allow system updates by setting
``MANAGED_K8S_RELEASE_THE_KRAKEN`` (see
:ref:`Environment Variables <environmental-variables.behavior-altering-variables>`.
Nodes will get updated one after another if they are already
initialized. Between the node updates, it is verified that the cluster
is healthy. These verification checks can be skipped by passing ``-s``.

.. code:: console

   $ # Trigger system updates of nodes
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/update-kubernetes-nodes.sh [-s]

.. _actions-references.upgradesh:

``upgrade.sh``
--------------

This script can be used to trigger a Kubernetes upgrade. More details
about that can be found :doc:`here </user/guide/kubernetes/upgrading-kubernetes>`.

.. _actions-references.verify-cluster-healthsh:

``verify-cluster-health.sh``
----------------------------

This script can be used to verify the Kubernetes cluster health.
It triggers the k8s-supplements playbook ``verify-cluster-health.yaml``.

.. _actions-references.wg-upsh:

``wg-up.sh``
------------

For clusters running on top of OpenStack,
access to the Kubernetes nodes is provided by
establishing a Wireguard tunnel to the gateway nodes.

When the Wireguard tunnel needs to be up, it is automatically setup by
all ``apply-*.sh``-scripts.

This script brings up the WireGuard VPN connection to the cluster.

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

.. _actions-references.libsh:

``lib.sh``
----------

The ``lib.sh`` is included by other action scripts and defines commonly
used variables and function definitions.
