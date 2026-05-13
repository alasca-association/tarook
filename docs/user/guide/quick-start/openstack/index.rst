.. _user.guide.quick-start.openstack:

Quickstart on OpenStack
#######################

.. toctree::
   :maxdepth: 2
   :hidden:

   10-system-requirements
   20-local-resources
   30-init-repo
   40-init-vault
   50-cluster
   60-vault
   70-deploy
   99-teardown


To create a Tarook cluster on top of OpenStack, follow the steps below.
You need to be able to spawn at minimum 3 instances in your OpenStack project,
by default this guide uses 10 instances (with typical flavors ca. 17 vCPUs and 32 GiB of RAM) and 4 floating IP adresses.
Note that
each instance of Tarook expects
the OpenStack project to be solely dedicated to it
(one Tarook instance per OpenStack project and nothing else),
so better start with an empty project.

If you run into issues have a look into our :doc:`FAQ </user/guide/faq>` first.
