FAQ and Troubleshooting
=======================

FAQ - Frequently Asked Questions
--------------------------------

.. _faq.how-do-i-ssh-into-my-cluster-nodes:

“How do I ssh into my cluster nodes?”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: console

   $ ssh -i <path to private key> <username>@<ip address>

-  ``<path to private key>``

   -  This should be the path to your private key matching the keypair
      specified by the environment variable ``TF_VAR_keypair``.

-  ``<username>``

   -  This should be the default user of the image you are deploying.
   -  By default this should be ``debian`` for the gateway nodes and ``ubuntu``
      for the master and worker nodes.

-  ``<ip address>``

   -  The gateway, worker and master nodes are all connected in a
      private network and all have unique private IP addresses.
      Additionally all gateway nodes are given floating IP addresses.
   -  When ssh-ing to one of the gateways you can either use its
      floating or its private IP address.
   -  Master and worker nodes are only accessible using their private IP
      addresses and the traffic to these nodes is always (transparently)
      routed via the gateway nodes.
   -  The use of a private IP address requires first setting up the
      wireguard tunnel.

      -  If it is not already up, you can set it up by running the
         :ref:`wg-up.sh <actions-references.wg-upsh>` script.

         .. code:: console

            $ ./managed-k8s/actions/wg-up.sh

“How can I test my yk8s-Cluster?”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We recommend testing whether your cluster was successfully deployed by
:ref:`manually logging into the
nodes <faq.how-do-i-ssh-into-my-cluster-nodes>` and/or by running:

.. code:: console

   $ ./managed-k8s/actions/test.sh

“How can I delete my yk8s-Cluster?”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can delete the yk8s-Cluster and all associated OpenStack resources
by triggering the :ref:`destroy.sh <actions-references.destroysh>` script.

.. Warning::

   Destroying a cluster cannot be undone.

.. note::

   The :doc:`configuration </user/reference/cluster-configuration>` of
   the cluster is neither deleted nor reset.

.. code:: shell

   # Destroy the yk8s cluster and delete all OpenStack resources
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8S_NUKE_FROM_ORBIT=true ./managed-k8s/actions/destroy.sh

Troubleshooting
---------------

“The ``apply-all.sh`` script cannot connect to the host nodes”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Error message:** ``failed to detect a valid login!``

-  First make sure you can :ref:`manually connect to the host nodes <faq.how-do-i-ssh-into-my-cluster-nodes>`.
-  You may need to explicitly specify which key Ansible shall use for connections, i.e.
   the private key file corresponding to the OpenStack key pair specified by the
   environment variable ``TF_VAR_keypair`` in ``~/.config/yaook-k8s/env``.
-  You can do this by setting the variable ``ansible_ssh_private_key_file`` on the
   command line via
   :ref:`the AFLAGS environment variable <environmental-variables.behavior-altering-variables>`:

   .. code:: console

      $ AFLAGS='-e ansible_ssh_private_key_file=/path/to/private_key_file' ./managed-k8s/actions/apply.sh

-  Further information is available `in the upstream documentation on
   Ansible connections <https://docs.ansible.com/ansible/latest/user_guide/connection_details.html>`__.

“My private wireguard key cannot be found”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Error message:**
``cat: '~/.wireguard/wg.key': No such file or directory``

-  Use an absolute path to specify the ``wg_private_key_file``
   environment variable in ``~/.config/yaook-k8s/env``.

“I can't ssh into my cluster nodes”
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Follow the instructions on
   :ref:`how to connect to the cluster via ssh <faq.how-do-i-ssh-into-my-cluster-nodes>`.
-  Ensure that your ssh key is in :ref:`a supported format <initialization.appendix>`.


The ``Get certificate information task`` of the ``k8s-master`` fails
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Error message:**
``AttributeError: 'builtins.Certificate' object has no attribute '_backend'``

-  Remove your local Ansible directory but make sure to not remove data
   you still need so make backup in case
   (e.g. ``mv ~/.ansible ~/.ansible.bak``)
-  see `this issue <https://gitlab.com/yaook/k8s/-/issues/441>`__
