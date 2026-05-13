Environment Variable Reference
==============================

The cluster management action scripts rely extensively on environment
variables to interact with the cluster. A full overview of the variables
is provided below. It is strongly recommended to read the whole document
before starting to :doc:`initialize a cluster repository </user/guide/quick-start/initialization>`
for the first time.

.. tip::

   It is recommended to use `direnv <https://direnv.net/>`__ to automatically
   set the required variables. The cluster repository contains an ``.envrc``
   which should be committed and contain all cluster specific settings.
   It sources ``~/.config/yaook-k8s/env`` which should contain all user specific
   settings which apply to all clusters.
   Additionally, ``.envrc.local`` is sourced which should not be committed and
   contain settings which are specific to cluster and user.

.. hint::

   This repository contains
   :ref:`a template file <environmental-variables.template>`
   which you can use. However, you **must** adjust some of its values.

.. _environmental-variables.minimal-required-changes:

Minimal Required Changes
------------------------

When initializing your env vars from the templates, you´ll need to
minimally (sic!) adjust the following ones:

1. User-specific changes to your personal environment in ``~/.config/yaook-k8s/env``:

   -  If you’re deploying on top of OpenStack:

      -  :ref:`SSH Configuration<environmental-variables.ssh-configuration>`

         -  ``TF_VAR_keypair`` (user specific)

      -  :ref:`VPN Configuration<environmental-variables.vpn-configuration>`

         -  ``wg_private_key_command`` (user specific)
         -  ``wg_user`` (user specific)

   -  If you’re deploying on top of Proxmox:

      -  :ref:`SSH Configuration<environmental-variables.ssh-configuration>`

         -  ``TF_VAR_ssh_key`` (user specific)

2. Cluster-specific changes to the cluster environment ``.envrc``:

   - :ref:`OpenStack Credentials <environmental-variables.openstack-credentials>`
      if the cluster shall be run on top of OpenStack.

     It is recommended to place these into a separate file ``.openrc`` which then
     can be sourced in the ``.envrc``.
     It is also highly recommended to not directly specify the ``OS_PASSWORD``,
     but to dynamically retrieve it from a secure place.

   - :ref:`Proxmox Credentials <environmental-variables.proxmox-credentials>`
     if the cluster shall be run on top of Proxmox.

     It is recommended to place these into a separate file ``.openrc`` which then
     can be sourced in the ``.envrc``.
     It is also highly recommended to not directly specify the ``PROXMOX_VE_PASSWORD``,
     but to dynamically retrieve it from a secure place.

   -  For potentially productive setups, setting
      ``YAOOK_K8S_CA_*_OVERRIDE`` as described in the template is
      **strongly encouraged**.

Details about these can be found below.

General
-------

=============================   ========    =============
Environment Variable            Default     Description
=============================   ========    =============
``MANAGED_K8S_COLOR_OUTPUT``                Boolean value which either force enables or
                                            force disables coloured output of the
                                            scripts. By default, the scripts check
                                            whether they are running inside a tty. If
                                            they are, they will use coloured output.
                                            This environment variable can be set to
                                            override the auto-detection.
=============================   ========    =============

.. _environmental-variables.openstack-credentials:

OpenStack credentials
---------------------

We support ``v3password`` (user name / password) and
``v3applicationcredential`` (application credentials) as authentication
schemes. They differ in the set of environment variables you have to
provide.

-  **Both** schemes need: ``OS_AUTH_URL``, ``OS_REGION_NAME``,
   ``OS_INTERFACE`` and ``OS_IDENTITY_API_VERSION``.

-  **User name/password based** authentication requires additionally:
   ``OS_PASSWORD``, ``OS_PROJECT_DOMAIN_ID``, ``OS_PROJECT_NAME``,
   ``OS_USERNAME``, ``OS_USER_DOMAIN_NAME``.

-  **Application credential** based authentication requires
   additionally: ``OS_AUTH_TYPE=v3applicationcredential``,
   ``OS_APPLICATION_CREDENTIAL_ID``,
   ``OS_APPLICATION_CREDENTIAL_SECRET``.

-  These **MUST** be set if you want to deploy on OpenStack.

-  These variables are used by Terraform to create, maintain and destroy
   the underlying harbour infrastructure layer. They are also needed by
   the `Cloud Controller Manager <https://kubernetes.io/docs/concepts/architecture/cloud-controller/>`__
   when applying the k8s-base layer.

.. warning::

   These credentials are copied into the cluster. You
   SHOULD use a dedicated OpenStack project for your cluster.

.. warning::

   Only use this exact set of variables. Using other,
   semantically similar variables (such as ``OS_PROJECT_DOMAIN_NAME``
   instead of ``OS_PROJECT_DOMAIN_ID``) is not supported and will lead
   to a broken cluster; the configuration files inside the cluster are
   generated solely based on the variables listed above.

Sample openrc for user name/password based authentication
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: shell

   export OS_AUTH_TYPE=v3password # optional
   export OS_AUTH_URL=https://identity.xyz:5000/v3
   export OS_PROJECT_ID=0xdeadbeef
   export OS_PROJECT_NAME="janedoes-project"
   export OS_USER_DOMAIN_NAME="Default"
   export OS_PROJECT_DOMAIN_ID="default"
   export OS_USERNAME="jane.doe@xyz"
   export OS_PASSWORD="super_secure"
   export OS_REGION_NAME="abcd"
   export OS_INTERFACE=public
   export OS_IDENTITY_API_VERSION=3

Sample openrc for application credentials based authentication
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: shell

   export OS_AUTH_TYPE=v3applicationcredential
   export OS_AUTH_URL=https://identity.xyz:5000/v3
   export OS_APPLICATION_CREDENTIAL_ID="0xdeadbeef"
   export OS_APPLICATION_CREDENTIAL_SECRET="alsoSuperSecure"
   export OS_REGION_NAME="abcd"
   export OS_INTERFACE=public
   export OS_IDENTITY_API_VERSION=3

.. _environmental-variables.proxmox-credentials:

Proxmox Credentials
-------------------

``PROXMOX_VE_ENDPOINT`` needs to be set to the endpoint of the Proxmox environment.

For authentication, use:

* Either ``PROXMOX_VE_USERNAME`` and ``PROXMOX_VE_PASSWORD``
* or ``PROXMOX_VE_API_TOKEN`` (takes precedence).

Sample env file
~~~~~~~~~~~~~~~

.. code:: shell

   export PROXMOX_VE_ENDPOINT=https://example.org:8000
   export PROXMOX_VE_USERNAME=myuser@pve
   export PROXMOX_VE_PASSWORD=mypassword

See `<https://registry.terraform.io/providers/bpg/proxmox/latest/docs#environment-variables-summary>`_ for further details.

External resources
------------------


======================================= ======================================================================= ===================================================
Environment Variable                    Default                                                                 Description
======================================= ======================================================================= ===================================================
``MANAGED_K8S_GIT``                     ``gitlab.com/alasca.cloud/tarook/tarook``                               This git URL is used by ``init-cluster-repo.sh`` to
                                                                                                                bootstrap the LCM (``Tarook``)
                                                                                                                repository. Can be used to override
                                                                                                                the repository to use another mirror.
``TERRAFORM_MODULE_PATH``               ``../terraform``                                                        Path to the Terraform root module to
                                                                                                                change the working directory for the
                                                                                                                execution of the Terraform commands.
======================================= ======================================================================= ===================================================

.. _environment-variables.secret-management:

Secret Management
-----------------

======================= =========== ================
Environment Variable    Default     Description
======================= =========== ================
``VAULT_ADDR``          (unset)     Address of the HashicorpVault server expressed
                                    as a URL and port.
``VAULT_TOKEN``         (unset)     Vault authentication token.
======================= =========== ================

.. _environmental-variables.vpn-configuration:

VPN Configuration
-----------------

============================= ======================= =======================
Environment Variable          Default                 Description
============================= ======================= =======================
``wg_conf_name``              ``"wg0"``               This variable defines the name
                                                      of the WireGuard interface to
                                                      create. The interface name
                                                      must match wg-quick's regex
                                                      ``[a-zA-Z0-9_=+.-]{1,15}``
                                                      and should start with ``wg``.
                                                      Examples: ``wg0``, ``wg-k8s-dev``.
                                                      This variable is used by the
                                                      ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``wg_endpoint``               ``0``                   The ID of the wireguard endpoint to use when connecting
                                                      to the VPN, as configured with
                                                      :ref:`configuration-options.yk8s.wireguard.endpoints`.
``wg_private_key_command``                            Command to retrieve a WireGuard private key from
                                                      a safe place, for example by using ``pass``.
                                                      This variable is used by the
                                                      ``wg-up.sh``-:ref:`script <actions-references.wg-upsh>`.
                                                      The key is injected via ``wg set`` to
                                                      prevent leakage.

                                                      Note that the command is called with an empty environment,
                                                      so any variables that it may need, have to be specified explicitly.

                                                      You **MUST** adjust this variable.

                                                      Example: ``export wg_private_key_command='PASSWORD_STORE_DIR='"'$PASSWORD_STORE_DIR'"' pass my-wg-key'``.

``wg_private_key_file``       ``"$(pwd)/../privkey"`` Path to your WireGuard private key
                                                      file. This is not copied to any
                                                      remote machine, but needed to
                                                      generate the local configuration
                                                      locally and to bring the VPN tunnel
                                                      up.
                                                      (DEPRECATED. Use ``wg_private_key_command``
                                                      instead.)
``wg_private_key``                                    Alternatively you can directly
                                                      export your WireGuard private key
                                                      if neither ``wg_private_key_command``
                                                      nor ``wg_private_key_file`` is set.
                                                      (DEPRECATED. Use ``wg_private_key_command``
                                                      instead.)
``wg_user``                   ``"firstnamelastname"`` Your WireGuard user name as
                                                      defined in the :ref:`wireguard configuration<configuration-options.yk8s.wireguard>`
                                                      (or, if enabled, ``wg_user`` `repository <https://gitlab.cloudandheat.com/lcm/wg_user>`__).
                                                      You **MUST** adjust this variable.
                                                      This variable is used by the
                                                      ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``wg_user``                   ``"firstnamelastname"`` Your WireGuard user name as
                                                      defined in the :ref:`wireguard configuration<configuration-options.yk8s.wireguard>`
                                                      (or, if enabled, ``wg_user`` `repository <https://gitlab.cloudandheat.com/lcm/wg_user>`__).
                                                      You **MUST** adjust this variable.
                                                      This variable is used by the
                                                      ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``TAROOK_WG_TO_K8S_NETWORKS``                         If set to ``true``, a tunnel to the Kubernetes Pod and Services network will be established as well.
                                                      This variable is used by the
                                                      ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
============================= ======================= =======================

.. _environmental-variables.ssh-configuration:

SSH Configuration
-----------------

=========================== =========================================== ====================
Environment Variable        Default                                     Description
=========================== =========================================== ====================
``TF_VAR_keypair``          ``"firstnamelastname-hostname-gendate"``    Defines the keypair name (in OpenStack) which will be used during the creation of new instances. Does not affect instances which have already been created. You **MUST** adjust this variable if you want to deploy on top of OpenStack. This variable is used by the ``apply-terraform.sh``:ref:`-script<actions-references.apply-terraformsh>`.
``TF_VAR_ssh_key``                                                      The public SSH key which will be used during the creation of new Proxmox VMs. Does not affect instances which have already been created. This variable is used by the ``apply-terraform.sh``:ref:`-script<actions-references.apply-terraformsh>`.
``MANAGED_K8S_SSH_USER``                                                The SSH user to use to log into the machines. This variable *SHOULD* be set. By default, the Ansible automation is written such that it’ll auto-detect one of the default SSH users (``centos``, ``debian``, ``ubuntu``) to connect to the machines. This only works if the machines were created with a keypair of which you hold the private key (see ``TF_VAR_keypair``).
=========================== =========================================== ====================

.. _environmental-variables.behavior-altering-variables:

Behavior-altering variables
---------------------------

The variables in this section should not be set during normal operation.
They disable safety checks or give consent to potentially dangerous
operations.

.. _environmental-variables.enabling-the-customization-layer:

=========================================== =========== ===================
Environment Variable                        Default     Description
=========================================== =========== ===================
``MANAGED_K8S_RELEASE_THE_KRAKEN``          ``false``   Boolean value which defaults to false. If set to ``true``, this allows the LCM to perform disruptive actions with Ansible. See the documentation on Disruption actions for details. By default, Ansible will avoid to perform any actions which could cause a loss of data or loss of availability to the customer. This comes at the cost of not performing certain operations or refusing to continue at some places.
``MANAGED_K8S_DISRUPT_THE_HARBOUR``         ``false``   Boolean value which defaults to false. If set to ``true``, this allows the LCM to perform disruptive actions to the harbour infrastructure (with Terraform).
``MANAGED_K8S_NUKE_FROM_ORBIT``             ``false``   Boolean value which defaults to false. If set to ``true``, it will delete all Thanos monitoring data from the object store before destruction.
``MANAGED_K8S_IGNORE_WIREGUARD_ROUTE``                  By default, ``wg-up.sh`` will check if an explicit route for the cluster network exists on your machine. If such a route exists and does not belong to the wireguard interface set via ``wg_conf_name``, the script will abort with an error.  The reason for that is that it is unlikely that you’ll be able to connect to the cluster this way and that weird stuff is bound to happen. If you know what you’re doing (I certainly don’t), you can set to any non-empty value to override this check.
``AFLAGS``                                              This allows to pass additional flags to Ansible. The variable is interpolated into the ansible call without further quoting, so it can be used to do all kinds of fun stuff. A primary use is to force diff output or only execute some tags: ``AFLAGS="--diff -t some-tag"``.
``TAROOK_NIX_FLAGS``                                    This allows to pass additional flags to the Nix inventory build process. The variable is interpolated into the ``nix build`` call without further quoting, so it can be used to do all kinds of fun stuff. It can primarily be used to pass the ``--impure`` or ``--debug`` flag to :ref:`update-inventory.sh <actions-references.update-inventorysh>`.
=========================================== =========== ===================

.. note::

   The destruction of the cluster will fail if Thanos
   monitoring data is still present in the object store. The reason for
   that is that terraform is not configured to delete the data by
   default. The reason for that, in turn, is that we want the operator
   to be aware that possibly contract-relevant monitoring data needs to
   be explicitly saved before destroying the cluster.

.. note::

   You should not use the ``AFLAGS``-mechanism to pass
   sustained variables to Ansible.
   See :ref:`cluster-configuration.custom-configuration` instead.

.. note::

   If you have already initialized you cluster repository,
   you’ll need to rerun the
   ``init-cluster-repo.sh``:ref:`-script <actions-references.init-cluster-reposh>`
   after enabling the Customization layer.

.. _environmental-variables.vault-tooling-variables:

Vault tooling variables
-----------------------

-  ``YAOOK_K8S_CA_ORGANIZATION_OVERRIDE``: Overrides the “organization”
   name in X.509 identities for CAs (root and intermediate) created by
   the Vault tooling.

-  ``YAOOK_K8S_CA_COUNTRY_OVERRIDE``: Overrides the “country” identifier
   in X.509 identities for CAs (root and intermediate) created by the
   Vault tooling.

-  ``VAULT_TOKEN``: Standard environment variable where the Vault CLI,
   all scripts and the LCM look for a ready-to-use token. Note that the
   LCM (and only the LCM, i.e. the ansible roles) ignores this variable
   if ``VAULT_AUTH_METHOD`` is set to a value different than ``token``.

-  ``VAULT_AUTH_METHOD`` (LCM only, default: ``token``): The
   authentication method to use for all orchestrator-controlled Vault
   operations. The only other supported value is ``approle``, which
   requires ``VAULT_AUTH_PATH``, ``VAULT_ROLE_ID`` and
   ``VAULT_SECRET_ID`` to be set.

-  ``VAULT_AUTH_PATH`` (LCM only, no default): Path to the
   authentication engine to use. Only used for non-``token``
   ``VAULT_AUTH_METHOD``.

-  ``VAULT_ROLE_ID`` (LCM only, no default): If ``VAULT_AUTH_METHOD`` is
   set to ``approle``, this must be set to the role ID to authenticate
   with.

-  ``VAULT_SECRET_ID`` (LCM only, no default): If ``VAULT_AUTH_METHOD``
   is set to ``approle``, this must be the secret ID to authenticate
   with.

-  ``YAOOK_K8S_VAULT_PATH_PREFIX`` (default: ``yaook``): Vault URI path
   prefix to be used for all secrets engines used by Tarook. Changing
   this is not fully supported and at your own risk.

-  ``YAOOK_K8S_VAULT_POLICY_PREFIX`` (default: ``yaook``): Vault policy
   name prefix to be used for all policies created by Tarook.
   Changing this is not fully supported and at your own risk.

-  ``YAOOK_K8S_VAULT_NODES_APPROLE_NAME`` (default:
   ``$YAOOK_K8S_VAULT_PATH_PREFIX/nodes``): Vault auth engine mount
   point to be used for the approle engine used to authenticate nodes.
   Changing this is not fully supported and at your own risk.



.. _environmental-variables.miscellaneous:

Miscellaneous
-------------

Variables which do not really fit into another category.

=========================================== =========== ===================
Environment Variable                        Default     Description
=========================================== =========== ===================
MINIMAL_ACCESS_VENV                         ``false``   Boolean value which defaults to ``false``. If set to ``true``, a minimal shell environment which contains barely enough packages to establish a connection to the cluster will be sourced when moving into the cluster repository.
YAOOK_K8S_DEVSHELL                          ``default`` Selects the devShell to be loaded. Possible values can be found in ``nix/dependencies.nix`` (dependency group names: `minimal`, `default`, ...).
YAOOK_K8S_DIRENV_MANUAL                     ``false``   If set to ``true``, the package environment is not updated automatically (e.g. when switching between branches) thus speeding up rebases etc. It can be manually updated with ``yaook-direnv-reload``.
=========================================== =========== ===================

.. _environmental-variables.template:

Template
--------

The template file is located at ``nix/templates/cluster-repo/.envrc`` and will be added to the cluster repository by :ref:`init-cluster-repo.sh <actions-references.init-cluster-reposh>`.

.. literalinclude:: /templates/envrc.template.sh
   :language: bash
