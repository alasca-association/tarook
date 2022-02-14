# Quick Start Guide

If you want to create a yk8s cluster on OpenStack, follow the following steps.
A bare-metal yk8s cluster requires further preparations.

Commands are assumed to be executed at the top level of the [cluster repository](./design/cluster-repository.md), if not stated otherwise.

If you are having problems, please visit our [FAQ](./faq.md).

---

1. [Install system requirements.](./usage/initialization.md#install-system-requirements)
1. [Create required resources.](./usage/initialization.md#required-system-resources)
1. [Initialize cluster repository.](./usage/initialization.md#create-and-initialize-cluster-repository)
1. Configure cluster in `./config/config.toml`.
    - If you plan on deploying OpenStack using yaook/operator on top of your yk8s cluster, please refer to the [cluster requirements of yaook/operator](https://docs.yaook.cloud/devel/requirements/k8s-cluster.html) to see which features are recommended or required to be present in your kubernetes cluster.
    - There are  [many configuration options available](./usage/cluster-configuration.md), but the minimum changes that need to be made to the configuration file are:
        - You need to add your gpg key to the [additional passwordstore users](./usage/cluster-configuration.html#passwordstore-configuration).
            - Please also ensure that your gpg keyring is up-to-date.
        - You need to add your (public) wireguard key to the [wireguard peer configuration](./usage/cluster-configuration.md#wireguard-configuration).
        - If your cluster runs on top of OpenStack, you can enable the [`ch-k8s-lbaas` loadbalancing.](./usage/cluster-configuration.md#configuring-load-balancing) If you do, you also need to create the `ch-k8s-lbaas.shared_secret` secret.
1. Deploy cluster by executing the [`apply.sh`](./operation/actions-references.md#applysh) script.
    ```console
    $ ./managed-k8s/actions/apply.sh
    ```
1. Get yourself a hot beverage and joyfully watch as your yk8s cluster gets created and tested.
1. [Start using your cluster](./faq.md#how-do-i-ssh-into-my-cluster-nodes).
