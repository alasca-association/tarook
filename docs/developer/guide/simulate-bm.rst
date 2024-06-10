Simulate self-managed bare-metal Setup on OpenStack
===================================================

This document describes how the self-managed bare-metal setup
can be simulated with OpenStack resources.
That's useful if you want to verify this use case
without having spare hardware available to do so.

The general approach is to utilize the Terraform stage
to create the harbour infrastructure
but then disable and remove everything in the environment
that is specific to the Openstack based setup path
before continuing.

Steps
-----

Cluster repository initialization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Follow the cluster :doc:`initialization documentation</user/guide/initialization>`.

Disable Wireguard in your ``.envrc``,
but enable Terraform because we want to use it to create
OpenStack resources:

.. code-block:: console

  $ export WG_USAGE=false
  $ export TF_USAGE=true

Configure the ``[terraform]`` section in your ``config/config.toml``.
Adjust the configuration to meet your needs:

.. code:: toml

  [terraform]

  subnet_cidr = "172.30.154.0/24"

  [terraform.master_defaults]
  image  = "Ubuntu 22.04 LTS x64"

  [terraform.worker_defaults]
  image  = "Ubuntu 22.04 LTS x64"

  [terraform.masters.0]

  [terraform.masters.1]

  [terraform.masters.2]

  [terraform.workers.0]
  flavor = "L"

  [terraform.workers.1]
  flavor = "L"

  [terraform.workers.2]
  flavor = "XL"

  [terraform.workers.3]
  flavor = "XL"

  [terraform.workers.4]
  flavor = "XL"

Creation of the harbour infrastructure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now we're ready to create the resources.

.. code:: console

  $ bash managed-k8s/actions/apply-terraform.sh

As this creates infrastructure for a cluster running on top of OpenStack,
we have to remove everything which does not apply to the
self-managed bare metal use case.
We're therefore going to delete all gateway nodes,
their ports and associated floating IPs:

.. code-block:: bash

  for gateway in managed-k8s-gw-0 managed-k8s-gw-1 managed-k8s-gw-2; do
      openstack server delete "$gateway"
      openstack floating ip delete $(openstack floating ip list --port "$gateway" -f value -c ID)
      openstack port delete "$gateway"
  done

Also remove the ``[gateways]`` section from the inventory ``inventory/yaook-k8s/hosts`` now
and replace ``gateways`` with ``masters`` in the ``[frontend:children]`` section.

We can now disable Terraform in our ``.envrc``:

.. code:: console

  $ export TF_USAGE=false

Create a jump host
~~~~~~~~~~~~~~~~~~

Without the gateway nodes, there is currently no way to connect
to the Kubernetes nodes from the outside.
To access the Kubernetes nodes, we're going to create a jump host.

Creating security group for the jump host:

.. code-block:: console

  $ openstack security group create ssh
  $ openstack security group rule create --protocol tcp --dst-port 22 --ingress ssh --egress <security group name>

Creating the jump host itself:

.. code:: console

  $ openstack server create --flavor XS --image <image name> --key-name <openstack ssh keypair name> --network managed-k8s-network --security-group default --security-group <security group name> mk8s-jump-host


Creating and attaching a floating ip to the jump host:

.. code:: console

  $ openstack floating ip create shared-public-IPv4 --port $(openstack port list --server mk8s-jump-host -f value -c ID)


The jump host should be accessible via the attached floating IP now.
We still want to harden it though.
For the LCM to work, we have to adjust the hosts file
which has been created previously by Terraform
``inventory/yaook-k8s/hosts``.

* Set ``on_openstack`` to ``false``
* Set ``networking_fixed_ip`` to the networking fixed ip created by Terraform
  * Check out the following vars-file: ``inventory/yaook-k8s/group_vars/all/terraform_networking-trampoline.yaml``
* Set ``subnet_cidr`` to the subnet cidr created by Terraform (and configured above in your ``config/config.toml``)
  * Check out the following vars-file: ``inventory/yaook-k8s/group_vars/all/terraform_networking-trampoline.yaml``
* Set ``ipv4_enabled`` to ``true``
* Set ``ipv6_enabled`` to ``false``
* Add the jump host as target

Your hosts file should end up similar to this:

.. code-block:: ini
  :emphasize-lines: 3,4,5,6,8,9,14,15

  [all:vars]
  ansible_python_interpreter=/usr/bin/python3
  on_openstack=False
  networking_fixed_ip=172.30.154.75
  subnet_cidr=172.30.154.0/24
  ipv6_enabled=False
  ipv4_enabled=True

  [other]
  mk8s-jump-host ansible_host=<floating ip> local_ipv4_address=172.30.154.104

  [orchestrator]
  localhost ansible_connection=local ansible_python_interpreter="{{ ansible_playbook_python }}"

  [frontend:children]
  masters

  [k8s_nodes:children]
  masters
  workers


  [masters]
  managed-k8s-master-0 ansible_host=172.30.154.245 local_ipv4_address=172.30.154.245
  managed-k8s-master-1 ansible_host=172.30.154.175 local_ipv4_address=172.30.154.175
  managed-k8s-master-2 ansible_host=172.30.154.254 local_ipv4_address=172.30.154.254


  [workers]
  managed-k8s-worker-0 ansible_host=172.30.154.237 local_ipv4_address=172.30.154.237
  managed-k8s-worker-1 ansible_host=172.30.154.29 local_ipv4_address=172.30.154.29
  managed-k8s-worker-storage-0 ansible_host=172.30.154.167 local_ipv4_address=172.30.154.167
  managed-k8s-worker-storage-1 ansible_host=172.30.154.18 local_ipv4_address=172.30.154.18
  managed-k8s-worker-storage-2 ansible_host=172.30.154.197 local_ipv4_address=172.30.154.197

SSH hardening the jump host
~~~~~~~~~~~~~~~~~~~~~~~~~~~

We're now ready to SSH harden the jump host via the custom stage.
Adjust the custom stage playbook ``k8s-custom/main.yaml``
and insert:

.. code:: yaml

  - name: Detect user mk8s-jump-host
    hosts: mk8s-jump-host
    gather_facts: false
    vars_files:
    - vars/k8s-core-vars/etc.yaml
    roles:
    - role: bootstrap/detect-user
      tags:
      - detect-user
      - always

  - name: Prepare mk8s-jump-host
    hosts: mk8s-jump-host
    become: true
    vars_files:
    - vars/k8s-core-vars/ssh-hardening.yaml
    - vars/k8s-core-vars/etc.yaml
    vars:
      ssh_allow_agent_forwarding: true
    roles:
    - role: devsec.hardening.ssh_hardening
      tags: harden-ssh

Unfortunately, it's not possible to configure agent forwarding
for SSH, but it will get disabled by the hardening role.
We have to manually enable it as we want to use `sshuttle <https://github.com/sshuttle/sshuttle>`__
to connect to the Kubernetes nodes:

.. code-block:: console

  # Connect to the jump host
  $ ssh debian@THAT_FLOATING_IP_YOU_ATTACHED

  # become root (or edit the file with sudo)
  $ debian@mk8s-jump-host:~$ sudo -i

  # Edit the ssh configuration and enable
  # ForwardAgent yes
  $ root@mk8s-jump-host:~# vim /etc/ssh/ssh_config

Note that this will get overwritten on consecutive rollouts of devsec hardening,
so you should revert the changes you did to the
custom stage playbook ``k8s-custom/main.yaml``
and ensure devsec hardening is not re-triggered.

Connect to the Kubernetes nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

At this point you should be able to connect to the nodes via ``sshuttle``

.. code:: console

  $ sshuttle -r debian@<floating ip of jump host> <terraform.subnet_cidr>

Keep that connection open.
We can now connect to the Kubernetes nodes.
You can verify that by trying to SSH onto a node.

.. note::

  Note that ``ping`` does not work through a sshuttle tunnel.

Applying the LCM
~~~~~~~~~~~~~~~~

We're now ready to start the LCM:

.. code:: console

  $ bash managed-k8s/actions/apply-all.sh

Simulating bare metal rook/Ceph
-------------------------------

For rook-ceph to to be able to spawn OSDs,
you need to attach volumes of desired size and type
to the storage nodes which then can be used:

.. code-block:: console

  $ openstack volume create --size <disk size> --type <desired disk type> <disk name>

  $ openstack server add volume <node name> <disk name>


Side notes
----------

Ensure ch-k8s-lbaas is disabled
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Ensure you disabled ch-k8s-lbaas:

.. code:: toml

  [ch-k8s-lbaas]
  enabled = false

Configuring Storage Classes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Ensure you're configuring sane storage classes for services you enabled.
In especially Hashicorp Vault by default uses the ``csi-sc-cinderplugin`` storage class
which is not available when not connecting the Kubernetes cluster to the
underlying OpenStack.

If you want to deploy Vault, set another storage class
in your ``config/config.toml``:

.. code:: toml

  [k8s-service-layer.vault]
  storage_class = "local-storage"
