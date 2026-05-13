.. _user.guide.quick-start.openstack:

Quickstart on OpenStack
#######################

.. toctree::
   :maxdepth: 2
   :hidden:

   10-system-requirements
   20-system-resources
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

1. :doc:`Prepare your environment </user/guide/quick-start/openstack/10-system-requirements>`
2. :doc:`Create required system resources </user/guide/quick-start/openstack/20-system-resources>`
3. :doc:`Initialize a cluster repository </user/guide/quick-start/openstack/30-init-repo>`
4. :doc:`Initialize the Vault Backend </user/guide/quick-start/openstack/40-init-vault>`
5. :doc:`Configure Tarook </user/guide/quick-start/openstack/50-cluster>`
6. :doc:`Apply the configuration to the Vault Backend </user/guide/quick-start/openstack/60-vault>`
7. :doc:`Deploy the cluster </user/guide/quick-start/openstack/70-deploy>`
8. :doc:`Tear down the cluster </user/guide/quick-start/openstack/99-teardown>`

If you run into issues have a look into our :doc:`FAQ </user/guide/faq>` first.
