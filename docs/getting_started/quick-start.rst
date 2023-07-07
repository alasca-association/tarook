Quick Start Guide
=================

If you want to create a yk8s cluster on OpenStack, follow the following
steps. A bare-metal yk8s cluster requires further preparations.

Commands are assumed to be executed at the top level of the :doc:`/concepts/cluster-repository`,
if not stated otherwise.

If you are having problems, please visit our :doc:`FAQ </getting_started/faq>`.

--------------

1. :ref:`Install system requirements. <initialization.install-system-requirements>`
2. :ref:`Create required resources. <initialization.required-system-resources>`
3. :ref:`Initialize cluster repository. <initialization.create-and-initialize-cluster-repository>`

4. Configure cluster in ``./config/config.toml``.

   -  If you plan on deploying OpenStack using yaook/operator on top of
      your yk8s cluster, please refer to the
      `cluster requirements of yaook/operator <https://docs.yaook.cloud/requirements/k8s-cluster.html>`__
      to see which features are recommended or required to be present in
      your kubernetes cluster.
   -  There are
      :doc:`many configuration options available </usage/cluster-configuration>`,
      but the minimum
      changes that need to be made to the configuration file are:

      -  You need to add your gpg key to the :ref:`additional passwordstore
         users <cluster-configuration.passwordstore-configuration>`.

         -  Please also ensure that your gpg keyring is up-to-date.

      -  You need to add your (public) wireguard key to the
         :ref:`wireguard peer configuration <cluster-configuration.wireguard-configuration>`.
      -  If your cluster runs on top of OpenStack, you can enable the
         ``ch-k8s-lbaas`` :ref:`loadbalancing <cluster-configuration.configuring-load-balancing>`.
         If you do, you also need to create the
         ``ch-k8s-lbaas.shared_secret`` secret.

5. :ref:`Initialize the Vault secret store. <initialization.initialize-vault-for-a-development-setup>`
6. Deploy cluster by executing the :ref:`apply.sh <actions-references.applysh>` script.
   
   .. code:: console
   
      $ ./managed-k8s/actions/apply.sh

7. Get yourself a hot beverage and joyfully watch as your yk8s cluster
   gets created and tested.


8. :ref:`Start using your cluster <faq.how-do-i-ssh-into-my-cluster-nodes>`.

