Use of HashiCorp Vault in YAOOK/K8s
===================================

As of Summer 2023, YAOOK/K8s exclusively supports
`HashiCorp Vault <https://vaultproject.io>`__ as backend for storing secrets.
Previously, passwordstore was used. Vault supports many different kinds
of secrets and in particular its support for managing PKIs made it
attractive for YAOOK/K8s.

A Vault instance can be the backend for one or more YAOOK/K8s clusters;
it is not required that each cluster has a separate Vault. It is also
possible to use the Vault instance for something else in addition to
hosting YAOOK/K8s clusters, though this is not recommended to avoid
accidental exposure of credentials.

Vault primer
------------

If you are already familiar with Vault, you can skip this section.

Vault is a secret storage engine. Secrets are organized in so-called
secrets engines. Each engine manages a different type of secret. For
YAOOK/K8s, the three most important secret engines are:

-  `SSH CA/Certificate management <https://www.vaultproject.io/docs/secrets/ssh>`__
   (``ssh``)
-  `Public-Key Infrastructure CA/Certificate management <https://www.vaultproject.io/docs/secrets/pki>`__
   (``pki``)
-  `Generic Key/Value <https://www.vaultproject.io/docs/secrets/kv/kv-v2>`__
   (``kv``, version 2)

Secrets are accessed via HTTPS. Secrets engines are mounted at a URL
path, so that everything at and below the mount point is handled by that
secrets engine.

For example, if we mount a ``kv`` engine at ``foo/`` and an ``ssh``
engine at ``bar/`` then ``https://vault-server/foo/xyz`` is handled by
the ``kv`` engine and ``https://vault-server/bar/baz`` is handled by the
``ssh`` engine. Any other path would cause a 404 (with exceptions, see
below).

In addition to secrets engines you mounted, Vault also has some internal
endpoints, as well as the ``auth/`` prefix under which authentication
methods live.

Authentication methods can, like secrets engines, be used in a very
modular fashion. For YAOOK/K8s, the
`approle <https://www.vaultproject.io/docs/auth/approle>`__ method
is most important. It allows to create role/secret pairs, which are
functionally identical to a username/password pair. These are intended
to be used by machine accounts and in YAOOK/K8s they are used to give
each node a unique credential.

Access to data in Vault, including authentication configuration, happens
via HTTPS calls. The actions on an item (create, update, delete) are
distinguished using standard HTTP methods (GET, POST, DELETE). The
access control is based on policies, which in turn grant access to
specific HTTP methods on paths. That way, very fine grained access
control is possible, even down into specific parts of a secret engine.

Organization of Data in Vault
-----------------------------

All secrets engines used by YAOOK/K8s are mounted below the ``yaook/``
path prefix. (This prefix is configurable, but that is not well-tested.)
Each cluster gets its own secrets engines, to improve the isolation
between different clusters. The per-cluster secrets engines are mounted
at ``yaook/$cluster_name/...``, where ``$cluster_name`` is configured in
``config.toml`` (``vault.cluster_name``).

The following six secrets engines are used:

-  ``yaook/$cluster_name/kv``, a KV2 engine for generic secrets
   (wireguard key, service account signing key, …)
-  ``yaook/$cluster_name/k8s-pki``, a CA to issue identities within the
   Kubernetes cluster (e.g. API server, nodes)
-  ``yaook/$cluster_name/k8s-front-proxy-pki``, a CA to prove the
   identity of the Kubernetes API server for API extensions
-  ``yaook/$cluster_name/etcd-pki``, a CA to issue identities within the
   etcd cluster (e.g. cluster peers, clients)
-  ``yaook/$cluster_name/ssh-ca``, an SSH certificate authority to allow
   verifying node SSH keys without prior knowledge

In addition to the secrets engines, YAOOK/K8s has a shared ``approle``
authentication method at ``yaook/nodes``. This auth method is used to
provide credentials for the individual nodes of all clusters.

Vault UI
--------

Vault comes with a web user interface. In order to access the web
interface, enter the cluster repository and run:

.. code:: console

   $ sensible-browser "$VAULT_ADDR/ui/"

The ``VAULT_ADDR`` environment variable is automatically provided if you
have ``actions/vault_env.sh`` sourced in your ``.envrc``, as is
recommended. ``sensible-browser`` is a Debian-ism. On non-Debian
distributions, you may want to ``echo "$VAULT_ADDR/ui/"`` instead and
just open that link.

After opening the web UI page, you need to log in. You can log in as
root using the root token. The root token can be displayed using:

.. code:: console

   $ echo "$VAULT_TOKEN"

Or copied into the (X) clipboard using (does not work on Wayland, most
likely):

.. code:: console

   $ echo "$VAULT_TOKEN" | xsel -bi

On the use of Ed25519 keys
--------------------------

By default, all scripts in this repository generate Ed25519 key pairs
for CA-level keys.

The reason for this is that elliptic curve keys are generally smaller
and thus easier to store offline, if your policies require such
treatment. Ed25519 is preferred over NIST-ECDSA, simply because based on
implementation issues in the recent years it seems to be the more robust
algorithm for long-term must-not-be-exposed secrets.

The downside is that this renders the setup incompatible with Ubuntu
versions older than 20.04 LTS (and probably other operating systems) due
to lack of support in the respective ``python3-cryptography`` package.

.. _vault.on-policies:

On policies
-----------

The ``vault/init.sh`` script (see below) creates Vault policies which
are used for and by the LCM. There are separate policies for K8s nodes,
K8s control plane nodes, gateway nodes, common nodes and the
orchestrator.

All except the orchestrator role are used by machines provisioned by the
LCM. The orchestrator role is designed to be used to *run* and use the
LCM. It has sufficient privileges to execute all scripts listed below,
except the ``init.sh`` script, but including the ``mkcluster-*.sh`` and
``import.sh`` scripts.

Hence, this role is rather powerful, but it’s still better than a root
token.

Using a token or approle account with the orchestrator role is the
recommended way to invoke the LCM. For development setups, the LCM
defaults to running with the root token.

To run the LCM with a custom token, set the ``VAULT_TOKEN`` environment
variable. To run the LCM with a custom approle, set the
``VAULT_AUTH_PATH``, ``VAULT_AUTH_METHOD=approle``, ``VAULT_ROLE_ID``
and ``VAULT_SECRET_ID`` environment variables (see also
:ref:`Vault tooling variables <environmental-variables.vault-tooling-variables>`).

.. note::
   Currently, only ``approle`` is supported as an auth method
   besides ``token``. Additional auth methods could be implemented as
   needed.

.. note::

   The approle-related environment variables described above are
   only supported by the ansible LCM. They are not supported by the
   ``vault`` CLI tool or the vault scripts. To use different privileges
   with those, manually log into Vault using the CLI and export the
   resulting token via the ``VAULT_TOKEN`` environment variable.

.. _vault.managing-clusters-in-vault:
