Quick Start Guide
=================

If you want to create a YAOOK/K8s cluster on OpenStack, follow the following
steps. A bare-metal YAOOK/K8s cluster requires further preparations.

Commands are assumed to be executed at the top level of the :doc:`/user/reference/cluster-repository`,
if not stated otherwise.

If you are having problems, please visit our :doc:`FAQ </user/guide/faq>`.

--------------

1. :ref:`Install system requirements. <initialization.install-system-requirements>`
2. :ref:`Create required resources. <initialization.required-system-resources>`
3. :ref:`Initialize cluster repository. <initialization.create-and-initialize-cluster-repository>`

4. Configure cluster in ``./config/default.nix``.

   .. note::
      If you plan on deploying OpenStack using `YAOOK/Operator <https://gitlab.com/yaook/operator>`_
      on top of your YAOOK/K8s cluster, please refer to the
      `cluster requirements of yaook/operator <https://docs.yaook.cloud/requirements/k8s-cluster.html>`__
      to see which features are recommended and required to be present in
      your Kubernetes cluster.

   -  There are
      :doc:`many configuration options available </user/reference/options/index>`,
      but the minimum
      changes that need to be made to the configuration file are:

      -  You need to add your (public) wireguard key to the
         :ref:`wireguard peer configuration <configuration-options.yk8s.wireguard.peers>`.

      -  As your cluster runs on top of OpenStack, you can enable the
         ``ch-k8s-lbaas`` :ref:`loadbalancing <configuration-options.yk8s.ch-k8s-lbaas>`
         to allow the creation of Kubernetes services of type
         `LoadBalancer <https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer>`_.
         If you want to do so, you also need to create the
         ``ch-k8s-lbaas.shared_secret`` secret.

      - Check
        :ref:`configuration-options.yk8s.openstack`
        for options that can be set, you need to change some of them to fit to your
        OpenStack cluster, e.g.
        the flavors, images, ... of the gateway, master and worker nodes.

5. Configure the Vault backend

   .. tabs::

      .. tab:: Use an existing Vault instance

         :ref:`Configure access to the Vault backend <environment-variables.secret-management>`
         by setting ``VAULT_ADDR`` in your cluster ``.envrc``.
         More details about Vault as backend is provided at :doc:`/user/guide/vault/vault`.

         After configuring the ``VAULT_ADDR``,
         you then have to source a root token as ``VAULT_TOKEN``
         and initialize and configure the Vault instance:

         .. code:: console

            $ # Create policies and initialize approles
            $ ./managed-k8s/tools/vault/init.sh

            $ # Prepare a new cluster inside Vault, putting the root CA keys inside Vault.
            $ ./managed-k8s/tools/vault/mkcluster-root.sh

      .. tab:: Use Vault development setup

         An option is provided to automatically spawn and configure a local Vault instance
         via docker for development setups.
         Please refer to :ref:`initialization.initialize-vault-for-a-development-setup`.

   After configuring the Vault backend,
   ensure you have a token with at least policy ``orchestrator`` sourced
   as ``VAULT_TOKEN``.
   This is automatically the case if you are using the development setup.

6. Deploy cluster by executing the :ref:`apply-all.sh <actions-references.apply-allsh>` script.

   .. code:: console

      $ ./managed-k8s/actions/apply-all.sh

7. Get yourself a hot beverage and joyfully watch as your YAOOK/K8s cluster
   gets created and tested.


8. :ref:`Start using your cluster <faq.how-do-i-ssh-into-my-cluster-nodes>`.
