Environment Variable Reference
==============================

The cluster management action scripts rely extensively on environment
variables to interact with the cluster. A full overview of the variables
is provided below. It is strongly recommended to read the whole document
before starting to :doc:`initialize a cluster repository </usage/initialization>`
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
   :ref:`a template file <envirnomental-variables.template>`
   which you can use. However, you **must** adjust some of its values.

.. _envirnomental-variables.minimal-required-changes:

Minimal Required Changes
------------------------

When initializing your env vars from the template, you´ll need to
minimally (sic!) adjust the following ones:

-  If you’re deploying on top of OpenStack:

   -  :ref:`OpenStack Credentials <envirnomental-variables.openstack-credentials>`
   -  SSH Configuration

      -  ``TF_VAR_keypair`` (user specific)

   -  VPN Configuration

      -  ``wg_private_key_file`` (user specific)
      -  ``wg_user`` (user specific)

-  If you’re deploying on top of Bare Metal:

   -  Disable ``TF_USAGE`` (cluster specific)
   -  Disable ``WG_USAGE`` (cluster specific)

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

.. _envirnomental-variables.openstack-credentials:

OpenStack credentials
---------------------

We support ``v3password`` (user name / password) and
``v3applicationcredential`` (application credentials) as authentication
schemes. They differ in the set of environment variables you have to
provide.

-  **Both** schemes need: ``OS_AUTH_URL``, ``OS_REGION_NAME``,
   ``OS_INTERFACE`` and ``OS_IDENTITY_VERSION``.

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

.. warning::

   Currently the combination of thanos and application
   credentials :ref:`is not supported <prometheus-stack.thanos>`.

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

External resources
------------------


======================================= ======================================================================= ===================================================
Environment Variable                    Default                                                                 Description
======================================= ======================================================================= ===================================================
``MANAGED_K8S_GIT``                     ``gitlab.com:yaook/k8s``                                                This git URL is used by ``init.sh`` to
                                                                                                                bootstrap the LCM (``yaook/k8s``)
                                                                                                                repository. Can be used to override
                                                                                                                the repository to use another mirror.
``MANAGED_K8S_WG_USER_GIT``             ``gitlab.cloudandheat.com:lcm/wg_user``                                 Git URL to a repository with wireguard
                                                                                                                keys to provision. Can be enabled by
                                                                                                                setting ``WG_COMPANY_USERS`` (see below).
``MANAGED_K8S_PASSWORDSTORE_USER_GIT``  ``gitlab.cloudandheat.com:lcm/mk8s-passwordstore-users``                Git URL to a repository with users to
                                                                                                                grant access to cluster secrets. Can be
                                                                                                                enabled by setting ``PASS_COMPANY_USERS``
                                                                                                                (see below).
``MANAGED_CH_ROLE_USER_GIT``            ``gitlab.cloudandheat.com:operations/ansible-roles/ch-role-users.git``  RL to the ch-role-users role submodule.
                                                                                                                Can be enabled by setting ``SSH_COMPANY_USERS``
                                                                                                                (see below).
``TERRAFORM_MODULE_PATH``               ``../terraform``                                                        Path to the Terraform root module to
                                                                                                                change the working directory for the
                                                                                                                execution of the Terraform commands.
======================================= ======================================================================= ===================================================

Secret Management
-----------------

======================= =========== ================
Environment Variable    Default     Description
======================= =========== ================
``PASS_COMPANY_USERS``  ``false``   If set to true, ``init.sh`` will clone the
                                    repository ``MANAGED_K8S_PASSWORDSTORE_USER_GIT``.
                                    The users in that repository will be
                                    granted access to the pass-based secret
                                    store.
======================= =========== ================

VPN Configuration
-----------------

=========================== ======================= =======================
Environment Variable        Default                 Description
=========================== ======================= =======================
``wg_conf_name``            ``"wg0"``               This variable defines the name
                                                    of the WireGuard interface to
                                                    create. Interface name length is
                                                    restricted to 15 bytes and should
                                                    start with ``wg``. Examples:
                                                    ``wg0``, ``wg-k8s-dev``.
                                                    This variable is used by the
                                                    ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``wg_private_key_file``     ``"$(pwd)/../privkey"`` Path to your WireGuard private key
                                                    file. This is not copied to any
                                                    remote machine, but needed to
                                                    generate the local configuration
                                                    locally and to bring the VPN tunnel
                                                    up. You **MUST** adjust this
                                                    variable or ``wg_private_key``.
                                                    This variable is used by the
                                                    ``wg-up.sh``-:ref:`script <actions-references.wg-upsh>`.
``wg_private_key``                                  Alternatively you can directly
                                                    export your WireGuard private key
                                                    instead of a path to it. The key
                                                    is injected via ``wg set`` to
                                                    prevent leakage. This variable is
                                                    used by the ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``wg_user``                 ``"firstnamelastname"`` Your WireGuard user name as
                                                    defined in the :ref:`wireguard configuration<cluster-configuration.wireguard-configuration>`
                                                    (or, if enabled, ``wg_user`` `repository <https://gitlab.cloudandheat.com/lcm/wg_user>`__).
                                                    You **MUST** adjust this variable.
                                                    This variable is used by the
                                                    ``wg-up.sh``:ref:`-script <actions-references.wg-upsh>`.
``WG_COMPANY_USERS``        ``false``               If set to true, ``init.sh`` will
                                                    clone the repository
                                                    ``MANAGED_K8S_WG_USER_GIT``. The
                                                    inventory updater will then
                                                    configure the wireguard users from
                                                    that repository.
=========================== ======================= =======================

.. _envirnomental-variables.ssh-configuration:

SSH Configuration
-----------------

=========================== =========================================== ====================
Environment Variable        Default                                     Description
=========================== =========================================== ====================
``TF_VAR_keypair``          ``"firstnamelastname-hostname-gendate"``    Defines the keypair name (in OpenStack) which will be used during the creation of new instances. Does not affect instances which have already been created. You **MUST** adjust this variable if you want to deploy on top of OpenStack. This variable is used by the ``apply-terraform.sh``:ref:`-script<actions-references.apply-terraformsh>`.
``MANAGED_K8S_SSH_USER``                                                The SSH user to use to log into the machines. This variable *SHOULD* be set. By default, the Ansible automation is written such that it’ll auto-detect one of the default SSH users (``centos``, ``debian``, ``ubuntu``) to connect to the machines. This only works if the machines were created with a keypair of which you hold the private key (see ``TF_VAR_keypair``). If the LCM is configured to roll out all relevant users from the `ch-users-databag <https://gitlab.cloudandheat.com/configs/ch-users-databag/>`__ via `ch-role-users <https://gitlab.cloudandheat.com/operations/ansible-roles/ch-role-users>`__ (see ``SSH_COMPANY_USERS``), you'll need to ensure that this the correct user is used when trying to bring up the SSH connection.
``SSH_COMPANY_USERS``       ``false``                                   If set to true, ``init.sh`` will clone the repository ``MANAGED_CH_ROLE_USER_GIT``. The inventory updater will then configure your inventory such that the ``ch-role-users`` role is executed in stage2 and stage3.
=========================== =========================================== ====================

.. _envirnomental-variables.behavior-altering-variables:

Behavior-altering variables
---------------------------

The variables in this section should not be set during normal operation.
They disable safety checks or give consent to potentially dangerous
operations.

.. _envirnomental-variables.enabling-the-customization-layer:

=========================================== =========== ===================
Environment Variable                        Default     Description
=========================================== =========== ===================
``MANAGED_K8S_RELEASE_THE_KRAKEN``          ``false``   Boolean value which defaults to false. If set to ``true``, this allows the LCM to perform disruptive actions. See the documentation on Disruption actions for details. By default, ansible and terraform will avoid to perform any actions which could cause a loss of data or loss of availability to the customer. This comes at the cost of not performing certain operations or refusing to continue at some places.
``MANAGED_K8S_NUKE_FROM_ORBIT``             ``false``   Boolean value which defaults to false. If set to ``true``, it will delete all Thanos monitoring data from the object store before destruction.
``MANAGED_K8S_IGNORE_WIREGUARD_ROUTE``                  By default, ``wg-up.sh`` will check if an explicit route for the cluster network exists on your machine. If such a route exists and does not belong to the wireguard interface set via ``wg_conf_name``, the script will abort with an error.  The reason for that is that it is unlikely that you’ll be able to connect to the cluster this way and that weird stuff is bound to happen. If you know what you’re doing (I certainly don’t), you can set to any non-empty value to override this check.
``TF_USAGE``                                ``true``    Allows to disable execution of the terraform stage by setting it to false. This is also taken into account by the inventory helper. Intended use case are bare-metal or otherwise pre-provisioned setups.
``AFLAGS``                                              This allows to pass additional flags to Ansible. The variable is interpolated into the ansible call without further quoting, so it can be used to do all kinds of fun stuff. A primary use is to force diff output or only execute some tags: ``AFLAGS="--diff -t some-tag"``.
``K8S_CUSTOM_STAGE_USAGE``                  ``false``   If set to true, ``init.sh`` will create a base skeleton for the :ref:`customization layer<abstraction-layers.customization>` in your cluster repository. Also the ``apply.sh``:ref:`-script<actions-references.applysh>` will now include the appliance of this stage.
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
   sustained variables to Ansible. These variables should be set in your
   Ansible configuration file or hosts file(s).

.. note::

   If you have already initialized you cluster repository,
   you’ll need to rerun the
   ``init.sh``:ref:`-script <actions-references.initsh>`
   after enabling the Customization layer.

.. _envirnomental-variables.vault-tooling-variables:

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
   prefix to be used for all secrets engines used by yaook/k8s. Changing
   this is not fully supported and at your own risk.

-  ``YAOOK_K8S_VAULT_POLICY_PREFIX`` (default: ``yaook``): Vault policy
   name prefix to be used for all policies created by yaook/k8s.
   Changing this is not fully supported and at your own risk.

-  ``YAOOK_K8S_VAULT_NODES_APPROLE_NAME`` (default:
   ``$YAOOK_K8S_VAULT_PATH_PREFIX/nodes``): Vault auth engine mount
   point to be used for the approle engine used to authenticate nodes.
   Changing this is not fully supported and at your own risk.



.. _envirnomental-variables.template:

Template
--------

The template file is located at ``templates/envrc.template.sh``.

.. literalinclude:: /templates/envrc.template.sh
   :language: bash
