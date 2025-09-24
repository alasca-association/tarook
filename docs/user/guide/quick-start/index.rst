Quickstart Guide
################

.. toctree::
   :maxdepth: 2
   :hidden:

   initialization
   cluster
   vault
   deploy
   teardown

To create a Tarook cluster on top of OpenStack, follow the steps below.
You need to be able to spawn at minimum 3 instances in your OpenStack project,
by default this guide uses 10 instances (with typical flavors ca. 17 vCPUs and 32 GiB of RAM) and 4 floating IP adresses.

Alternatively setting up on bare metal requires additional preparations which are not covered by this guide.

.. note::

   Commands are assumed to be executed at the top level of the :doc:`cluster repository </user/reference/cluster-repository>`,
   if not stated otherwise.


1. :doc:`Prepare your environment and initialize a cluster repository </user/guide/quick-start/initialization>`
2. :doc:`Configure your Cluster </user/guide/quick-start/cluster>`
3. :doc:`Configure the Vault Backend </user/guide/quick-start/vault>`
4. :doc:`Deploy the Cluster </user/guide/quick-start/deploy>`
5. :doc:`Tear down the Cluster </user/guide/quick-start/teardown>`

If you run into issues have a look into our :doc:`FAQ </user/guide/faq>` first.
