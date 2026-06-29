Tarook exclusively supports `HashiCorp Vault <https://vaultproject.io>`__
as backend for storing secrets.
For details on the use of Vault in Tarook, please see the
:doc:`Use of HashiCorp Vault in Tarook </developer/explanation/vault>` section.

At the time of writing
there is no documentation on how to create a production-ready Vault backend yet
but for testing purposes you may use the development setup [#vault-dev-setup-caveats]_
which automatically sets up a Vault instance in a local container.

.. [#vault-dev-setup-caveats] Note that the development Vault setup
   is built for ease-of-use
   and no special care is taken security-wise (stores unseal key and root token on disk)

.. note::

   We assume you have setup a container runtime like e.g. ``docker`` or ``podman``!

1. Ensure that sourcing (comment it in) ``vault_env.sh`` is part of your cluster ``.envrc``.

   .. code:: console

      $ sed -i '/#source \"\$(pwd)\/managed-k8s\/actions\/vault_env.sh\"/s/^#//g' .envrc

2. Enable the :ref:`development environment<environmental-variables.miscellaneous>`:

   .. code:: console

      $ sed -i '/#[[:blank:]]*export YAOOK_K8S_DEVSHELL=/s/^#//g' ~/.config/yaook-k8s/env

3. Ensure that setting ``USE_VAULT_IN_DOCKER`` to ``true`` is part of your cluster ``.envrc``.
   This will activate the Vault development setup.

   .. code:: console

      $ sed -i '/export USE_VAULT_IN_DOCKER=false/s/false/true/g' .envrc
      $ sed -i '/#export USE_VAULT_IN_DOCKER=/s/^#//g' .envrc

   .. hint::

      If you are using rootless docker or podman,
      additionally set ``VAULT_IN_DOCKER_USE_ROOTLESS=true``
      in ``~/.config/yaook-k8s/env``

4. Don't forget to allow your changes:

   .. code:: console

      $ direnv allow .envrc

5. Start the docker container:

   .. code:: console

      $ ./managed-k8s/actions/vault.sh

   .. warning::
      This is not suited for productive deployments or production use,
      for many reasons!
