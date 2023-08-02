Cluster Repository
==================

The cluster repository is a git repository. It holds all information
which define the (intended) state of a cluster. This information
consists of:

-  The version of the LCM code to deploy the cluster
-  The version of the WireGuard user information
-  State of Terraform
-  State of the WireGuard IP address management (IPAM)
-  Secrets and credentials obtained while deploying the cluster
-  A :doc:`configuration </usage/cluster-configuration>` file which
   defines the platform layout and other properties of the cluster

A user checks out the cluster repository and uses it to interact with
the yk8s-cluster.

Cluster Repository Structure
----------------------------

The following schema shows all non-generated files. A local checkout
will most certainly have more files than these.

::

   your_cluster_repo
   ├── config/
   │   ├── config.toml               # Cluster configuration
   │   └── wireguard_ipam.toml       # WireGuard IPAM
   ├── etc/                          # Cluster-specific files
   ├── inventory/
   │   └── yaook-k8s/                # Variables passed to Ansible
   ├── k8s-custom/                   # Custom Stage
   │   ├── roles/                    # Dump in personal Ansible roles
   │   └── main.yaml
   ├── managed-k8s/                  # Submodule with the LCM code
   ├── submodules/                   # Place for additional git submodules
   ├── terraform/
   │   ├── .terraform/
   │   │   └── plugins/
   │   │       └── linux_amd64/
   │   │           └── lock.json     # Terraform plugin version lock
   │   ├── terraform.tfstate         # Terraform state
   │   └── terraform.tfstate.backup  # Terraform state backup
   ├── vault/                        # Local vault data
   ├── .envrc                        # direnv (env var) configuration
   ├── .gitattributes
   └── .gitignore

Detailed explanation:

-  ``config/config.toml`` holds the
   :doc:`configuration </usage/cluster-configuration>` variables of
   the cluster. A template for this file can be found in the
   ``templates/`` directory.

   Note that the :doc:`initialization </usage/initialization>`
   script ``init.sh`` will bootstrap your configuration from that
   template.

-  ``config/wirguard_ipam.toml`` contains the
   :doc:`Wireguard </vpn/wireguard>` IP address management.
   This file is only of interest if your want to protect your cluster with gateway nodes.
   This file is managed by the
   :ref:`update_inventory.py <actions-references.update_inventorypy>` script.
   This script will automatically assign IP addresses to your
   :ref:`configured peers <cluster-configuration.wireguard-configuration>`.

-  The ``inventory/`` directory holds your
   :doc:`layer-specific </concepts/abstraction-layers>` Ansible variables. These
   variables are managed by the
   :ref:`update_inventory.py <actions-references.update_inventorypy>` script.

-  ``etc/`` holds credentials and cluster-specific files
   generated during creation of the cluster.
   Nearly all credentials are managed by an Hashicorp vault instance though.

-  ``k8s-custom/`` is an optional directory representing the
   :doc:`custom layer </concepts/abstraction-layers>`. It is the basic
   skeleton to enable custom Ansible plays. If you want to use this
   feature, you’ll need to
   :ref:`enable it in your environment variables <environmental-variables.behavior-altering-variables>`.

-  ``managed-k8s/`` is a git submodule which refers to this (the
   ``yaook/k8s``) repository. By using a submodule, we get a pinning to
   an exact commit and hold the hash of that commit inside the cluster
   repository. This allows us to reproducibly roll out the cluster with
   the same state without changes again, even if the branch of
   ``managed-k8s`` has advanced in the meantime.

-  ``terraform/`` is a state-only directory for Terraform. You should
   not need to manually operate in that directory at all. The terraform
   state is managed by the
   :ref:`apply-terraform.sh <actions-references.apply-terraformsh>` script.

*Optional:*

-  ``submodules/`` is a directory which holds optional git submodules.
   You can add your submodules to this directory and e.g. use them in
   the :doc:`custom layer/stage </concepts/abstraction-layers>`. Since this
   project is largely managed by C&H and partners, we have taken the
   privilege to be able to enable and integrate company specific
   submodules directly in the source code.

   If you're managing your wireguard peers or SSH users via git
   repositories, these should be added here.

Cluster-User Interaction
------------------------

.. figure:: /img/cluster-user-interaction.svg
   :scale: 100%
   :alt: Cluster-User-interaction Visualization
   :align: center

   Cluster-User interaction communication flow visualization
