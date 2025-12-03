.. _configuration-options.yk8s.hooks:

yk8s.hooks
^^^^^^^^^^



.. _configuration-options.yk8s.hooks.post_uncordon_roles:

``yk8s.hooks.post_uncordon_roles``
##################################

Defines the roles which should be executed after uncordoning the Kubernetes node.

Custom roles may be placed into ``k8s-custom/roles``.


**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/hooks.nix


.. _configuration-options.yk8s.hooks.pre_drain_roles:

``yk8s.hooks.pre_drain_roles``
##############################

Defines the roles which should be executed before draining the Kubernetes node

**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/hooks.nix

