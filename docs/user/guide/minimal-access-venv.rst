Minimal Access Venv
===================

For users requiring access to given cluster repositories
but not frequently operating on these via the LCM,
poetry will probably have to update and download a lot of Python packages.

The option to just source a minimal virtual Python environment
is given via ``MINIMAL_ACCESS_VENV`` (:ref:`Miscellaneous <environmental-variables.miscellaneous>`).
If enabled, the bare minimum of Python packages to be able
to establish a connection to the Kubernetes API is installed.

This is in especially useful for quick incident resolutions
where using the LCM is not required to get a first overview.

Configure minimal access globally
---------------------------------

Minimal access can be configured globally for all cluster repositories
by setting it in ``~/.config/yaook-k8s/env``.

.. code:: shell

  export MINIMAL_ACCESS_VENV=true

Configure minimal access per cluster repository
-----------------------------------------------

Minimal access can be configured per cluster repository
by setting it inside of ``$CLUSTER_REPOSITORY/.envrc.local``.

.. code:: shell

  export MINIMAL_ACCESS_VENV=true

Deconfigure minimal access
--------------------------

If you need a full environment to be able to make us of the LCM again,
you can simply unset ``MINIMAL_ACCESS_VENV`` or set it to ``false``
and reload your ``direnv``.

.. code:: shell

  # Ensure it is unset or set to false
  export MINIMAL_ACCESS_VENV=false

  # Move into the cluster repository and
  direnv reload .
