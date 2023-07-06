Wireguard
=========

Basic setup
-----------

1. Create a Wireguard keypair as described
:ref:`here <initialization.required-system-resources>`.

2. Set your Wireguard user and path to the private key
:ref:`as environment variable <environmental-variables.minimal-required-changes>`.

3. Add your Wireguard user and public key as peer in
:ref:`config.toml <cluster-configuration.wireguard-configuration>`.

4. The Wireguard configuration on the frontend nodes is updated when executing
:ref:`stage 2 <actions-references.apply-stage2sh>`.

Establishing and closing a Wireguard connection
-----------------------------------------------
The connection to the Wireguard server can be established by running the
:ref:`wg-up.sh action <actions-references.wg-upsh>`.

An established connection can be closed by running ``wq-quick down $wg_conf_name``.

Rotating Wireguard Server Key
-----------------------------
For security reasons, the Wireguard server key should be rotated from time to time,
especially when someone should not have access to the cluster anymore.

It is possible to configure multiple Wireguard endpoints on the frontend nodes.
The part of ``config.toml`` for the default endpoint (id ``0``) looks like this:

.. code:: toml

   [[wireguard.endpoints]]
   id = 0
   enabled = true
   port = 7777
   ip_cidr = "172.30.153.64/26"
   ip_gw   = "172.30.153.65/26"

Every endpoint needs its own unique id, port, subnet and gateway address.
The same subnet cannot be used by more than one wireguard endpoint!

The endpoint that should be used by :ref:`wg-up.sh <actions-references.wg-upsh>` can be
selected by setting ``wg_endpoint`` to the according ``id`` in ``.envrc``
(or some other place where the environment is set).

With that in mind, the Wireguard server key can be rotated by doing the following steps:

1. Add a new Wireguard endpoint in ``config.toml``. Example:

.. code:: toml

   [[wireguard.endpoints]]
   id = 1
   enabled = true
   port = 7778
   ip_cidr = "172.30.153.128/26"
   ip_gw   = "172.30.153.129/26"

2. Execute :ref:`stage 2 <actions-references.apply-stage2sh>`.

3. Change the default endpoint id to the newly created endpoint in ``.envrc``
   (``wg_endpoint``).

4. Check if the new endpoint works correctly (close and establish the Wireguard tunnel
   and check for correct IP address and subnet).

5. Notify users about the new endpoint, distribute new Wireguard public key and
   generated config files (``inventory/.etc/wireguard/wg1/*.conf``), set a deadline for
   switching to the new endpoint.

6. Wait until deadline is reached.

7. Set ``enabled = false`` on the old Wireguard endpoint and run
   :ref:`stage 2 <actions-references.apply-stage2sh>`. The old endpoint is now disabled.

8. Remove old config files at ``inventory/.etc/wireguard/wg0/``, the old private key
   (``wireguard/wg0-key`` in the vault) and the old endpoint section in ``config.toml``.

IPAM
----
All configured Wireguard peers receive an IP-address from the Wireguard subnet
(``ip_cidr``).
The IP-address assignment is then saved in ``config/wireguard_ipam.toml``.

Peer Config Files
-----------------
Wireguard configurations files for all peers are generated at
``inventory/.etc/wireguard/wgX``. The files can be given out to the corresponsing peers
to enable them to connect to the cluster.

Legacy Configuration
--------------------
With the switch from one fixed Wireguard endpoint to the option to have multiple
Wireguard endpoints, the structure of the Wireguard config in ``config.toml`` has
changed.

The old config format is still supported. This means that a config like

.. code:: toml

   ...
   [wireguard]
   ip_cidr = "172.30.153.64/26"
   ip_gw   = "172.30.153.65/26"

   ipv6_cidr = "fd01::/120"
   ipv6_gw = "fd01::1/120"

   port = 7777
   ...

is interpreted as

.. code:: toml

   ...
   [wireguard]
   [[wireguard.endpoints]]
   id = 0
   enabled = true
   port = 7777
   ip_cidr = "172.30.153.64/26"
   ip_gw   = "172.30.153.65/26"
   ipv6_cidr = "fd01::/120"
   ipv6_gw = "fd01::1/120"
   ...

However the old format is considered as deprecated and support for it will be dropped
at some time.
