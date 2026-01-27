.. _configuration-options.yk8s.vault:

yk8s.vault
^^^^^^^^^^



.. _configuration-options.yk8s.vault.cluster_name:

``yk8s.vault.cluster_name``
###########################

Name of the cluster inside Vault. The secrets engines are searched for
relative to $path_prefix/$cluster_name/.
This name must be unique within a single vault instance and cannot be
reasonably changed after a cluster has been spawned.


**Type:**::

  Segment of a Hashicorp Vault namespace


**Default:**::

  "\${config.yk8s.infra.cluster_name}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/vault.nix


.. _configuration-options.yk8s.vault.nodes_approle:

``yk8s.vault.nodes_approle``
############################



**Type:**::

  Name of a Hashicorp Vault namespace


**Default:**::

  "yaook/nodes"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/vault.nix


.. _configuration-options.yk8s.vault.path_prefix:

``yk8s.vault.path_prefix``
##########################



**Type:**::

  Name of a Hashicorp Vault namespace


**Default:**::

  "yaook"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/vault.nix


.. _configuration-options.yk8s.vault.policy_prefix:

``yk8s.vault.policy_prefix``
############################



**Type:**::

  Name of a Hashicorp Vault namespace


**Default:**::

  "yaook"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/vault.nix

