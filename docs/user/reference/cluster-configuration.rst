Cluster Configuration
=====================

The :doc:`environment variables </user/reference/environmental-variables>`
affect how the user interact with the cluster via the
:doc:`action scripts </user/reference/actions-references>`. The directory
``config/`` however holds the configuration of the cluster itself
and can be adjusted to customize the yk8s cluster to fit your needs. It also
contains operational flags which can trigger operational tasks.

The ``config/default.nix`` configuration file
---------------------------------------------

After
:doc:`initializing a cluster repository </user/guide/initialization>`,
``config/default.nix`` contains a minimal configuration with default values.
However, you’ll still need to adjust some of them before
triggering cluster creation.

When an action script is run, Nix automatically reads the configuration file,
processes it, and puts variables into the ``inventory/``. The ``inventory/``
is automatically included. Following the concept of separation of concerns,
variables are only available to stages/layers which need them.

For all available options see :doc:`options/index`

The ``config/config.toml`` configuration file
---------------------------------------------

The ``config.toml`` is the legacy configuration file and can be imported in
``default.nix`` to allow for gradual migration.
.

Custom Configuration
--------------------

Since yaook/k8s allows to
:ref:`execute custom playbook(s) <abstraction-layers.customization>`, the
custom section allows you to specify your own custom variables to be
used in these.

.. raw:: html

   <details>
   <summary>Custom Configuration</summary>

.. code:: nix

   custom = {
      my_custom_variable = "mycustomvalue";
   };

.. raw:: html

   </details>

|

.. _cluster-configuration.ansible-configuration:

Ansible Configuration
---------------------

The Ansible configuration file can be found in the ``ansible/``
directory. It is used across all stages and layers.

.. raw:: html

   <details>
   <summary>Default Ansible configuration</summary>

.. literalinclude:: /templates/ansible.cfg
   :language: ini

.. raw:: html

   </details>
