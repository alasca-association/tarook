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

4. Configure cluster in ``./config/config.toml``.

   .. note::
      If you plan on deploying OpenStack using `yaook/operator <https://gitlab.com/yaook/operator>`_
      on top of your YAOOK/K8s cluster, please refer to the
      `cluster requirements of yaook/operator <https://docs.yaook.cloud/requirements/k8s-cluster.html>`__
      to see which features are recommended and required to be present in
      your Kubernetes cluster.

   -  There are
      :doc:`many configuration options available </user/reference/cluster-configuration>`,
      but the minimum
      changes that need to be made to the configuration file are:

      -  You need to add your (public) wireguard key to the
         :ref:`wireguard peer configuration <cluster-configuration.wireguard-configuration>`.

      -  As your cluster runs on top of OpenStack, you can enable the
         ``ch-k8s-lbaas`` :ref:`loadbalancing <cluster-configuration.configuring-load-balancing>`
         to allow the creation of Kubernetes services of type
         `LoadBalancer <https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer>`_.
         If you want to do so, you also need to create the
         ``ch-k8s-lbaas.shared_secret`` secret.

      - Check for
        :doc:`terraform variables</developer/reference/terraform-docs>`
        that can be set, you need to change some of them to fit to your
        OpenStack cluster, e.g.
        the flavors, images, ... of the gateway, master and worker nodes.

5. :ref:`Initialize the Vault secret store. <initialization.initialize-vault-for-a-development-setup>`
6. Deploy cluster by executing the :ref:`apply-all.sh <actions-references.apply-allsh>` script.

   .. code:: console

      $ ./managed-k8s/actions/apply-all.sh

7. Get yourself a hot beverage and joyfully watch as your YAOOK/K8s cluster
   gets created and tested.


8. :ref:`Start using your cluster <faq.how-do-i-ssh-into-my-cluster-nodes>`.
