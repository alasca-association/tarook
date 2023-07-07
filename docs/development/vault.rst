Developing with Vault
=====================

The Vault development setup
---------------------------

The Vault development setup is managed by
``./managed-k8s/actions/vault.sh``. It is enabled by setting
``USE_VAULT_IN_DOCKER`` to true in your environment file.

This will spawn a local Vault instance with its data and unseal keys
inside the cluster repository. Thanks to dynamic binding of the port
numbers and dynamic configuration of the environment via
``./managed-k8s/actions/vault_env.sh``, it is possible to work with
multiple cluster repositories in parallel.

Using Vault from Ansible
------------------------

Vault is accessed from Ansible using
`community.hashi_vault <https://github.com/ansible-collections/community.hashi_vault>`__.
When writing code to access Vault, we need to take the three scenarios
into account:

1. Local development setup: The nodes cannot directly reach the Vault
   instance. Ansible runs with elevated privileges in Vault (compared to
   the nodes), i.e. with at least
   :ref:`the orchestrator policy <vault.on-policies>`.

2. Managed Kubernetes productive setup: The nodes may be able to
   directly access their Vault instance. Ansible runs with elevated
   privileges in Vault (compared to the nodes), i.e. with at least
   :ref:`the orchestrator policy <vault.on-policies>`.

3. Metal controller firstboot: The nodes are able to directly access
   their Vault instance. Ansible runs locally on the node with node
   privileges only.

Each node gets its own approle account in Vault. An approle account is
identified by the Role ID and the Secret ID. These credentials are
written into ``/etc/vault/`` by Ansible (in scenarios 1 and 2) or by the
bootstrap scripts of metal-controller (in scenario 3).

In order to ensure that code works in all three scenarios, the following
things are true in particular:

-  All access to Vault should happen using the role-id and secret-id of
   the node. This ensures that there will be no surprises when code is
   first run in scenario 3, where the role-id and secret-id of the node
   are the only option.

-  All access to Vault should be either in lookups or explicitly
   delegated to localhost. This is required for scenario 1, where the
   Vault is not reachable from the nodes.

-  The role-id and secret-id should be read from the filesystem on the
   remote node. By depending on ``vault-approle`` (only available in
   stage 2 and stage 3), the credentials are made available in the
   ``vault_node_role_id`` and ``vault_node_secret_id`` facts. The
   role-id and secret-id are not otherwise known and it requires
   orchestrator access to obtain or reset them (which is not available
   in scenario 3).

The only exceptions are explicitly privileged (orchestrator) actions,
which must be guarded by corresponding checks. For an example of this,
see the ``vault-onboarded`` role, which manages the Vault identity of
nodes in scenarios 1 and 2 (but not in scenario 3, because it doesn’t
run with orchestrator privileges).
