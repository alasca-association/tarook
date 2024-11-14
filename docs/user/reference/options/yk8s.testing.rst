.. _configuration-options.yk8s.testing:

yk8s.testing
^^^^^^^^^^^^


The following configuration section can be used to ensure that smoke
tests and checks are executed from different nodes. This is disabled by
default as it requires some prethinking.

.. _configuration-options.yk8s.testing.force_reboot_nodes:

``yk8s.testing.force_reboot_nodes``
###################################

Enforce rebooting of nodes after every system update


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/testing.nix


.. _configuration-options.yk8s.testing.test-nodes:

``yk8s.testing.test-nodes``
###########################

You can define specifc nodes for some
smoke tests. If you define these, you
must specify at least two nodes.


**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/testing.nix

