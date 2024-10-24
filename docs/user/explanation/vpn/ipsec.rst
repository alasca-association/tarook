IPsec
=====

.. todo::

   needs complete rewrite to become nice

This document should become a comprehensive documentation on the ipsec
setup. I will feed it my notes and experiences along the way. I created
the role ``ipsec-vpn`` that is part of stage2, i.e., strongswan will be
rolled out on the gateway nodes. This setup ought to be pretty similar
to wireguard. I am not sure yet what of the settings around wireguard
will be helpful / sufficient for ipsec (forwarding, mtu). Also I don’t
know yet if there will be a conflict between ipsec and wireguard.
wireguard should remain the default VPN solution.

Tools over which I stumbled: - strongswan - strongswan-starter -
charon(-cmd) - swanctl - ``Pluto`` seems to refer to the old IKEv1
daemon. ``Charon`` is a fresh re-implementation that aims to be
compatible to Pluto and implements to IKEv1 and IKEv2.

I followed the instructions on
`digitalocean.com <https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-20-04#step-6-%E2%80%94-configuring-the-firewall-&-kernel-ip-forwarding>`__
for a basic setup. The author proposes eap-mschapv2 as authentication
(?) scheme. IPsec should not be tunneled via wireguard. Instead we need
to use the public floating ip.

IPsec itself is implemented inside the kernel. The userspace tooling is
responsible to configure the network and handle the authentication.
IPsec use IKE, the Internet Key Exchange protocol. “Charon” is the
ferryman of Hades who carries souls across the Styx to the world of the
dead.

``strongswan`` is a systemd service that invokes swanctl. It invokes
``charon-systemd``. ``swanctl`` replaces the ``starter``, ``ipsec`` and
``stroke`` tools.

   ``swanctl`` works independantly from ipsec.conf.

Does that mean I configured the wrong configuration file
(``/etc/ipsec.d/ipsec.conf``)?

On Arch, ``strongswan`` invokes ``swanctl``. On Debian it uses
``starter`` and ``charon``. That means the tooling is different :O and
no surprise that I didn’t see any errors yet.

``VICI`` is the “Versatile IKE Configuration Interface”. It’s an
interface to configure, control and monitor the IKE daemon ``charon``.

An example that uses ``strongswan-swanctl`` can be found
`here <https://www.strongswan.org/testing/testresults/swanctl/rw-eap-mschapv2-id-rsa/>`__.
`Here <https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2Examples>`__
you can find more examples.

``/etc/swanctl/`` contains the configuration of
`swanctl <https://wiki.strongswan.org/projects/strongswan/wiki/SwanctlDirectory>`__.

What do I put in ``local_addrs``, what in ``remote_addrs``? What is
``remote_ts``? My laptop is behind a NAT, the gateway does not know
about its public endpoint. ``TS`` is ``traffic selector``. Split
tunneling is the name of a scenario in which a client only sends traffic
for specific destinations to the gateway. The initiator of an IPsec
tunnel can request an additional IP address from the responder to use as
an inner tunnel address. This address is called the ``Virtual IP``
``local_addrs`` defaults to ``%any`` if not set and is hence optional.
It’s useful if one wants to limit traffic to a particular interface.

The responder (server/gateway) does not receive a virtual ip. On the
other hand, why should it? VirtualIP is cool in a setup in which the
initiator is behind a NAT and cannot be reached.

How do I see that a tunnel is established? Where do I see any error
messages? Where can I turn up the volume? ``strongswan.conf`` contains
the configuration of ``charon-systemd``.
``/etc/strongswan.d/charon-systemd.conf`` looks like a promising spot.
`Wiki <https://wiki.strongswan.org/projects/strongswan/wiki/LoggerConfiguration>`__.
``default = 2`` sets the verbosity of all services that are not
explicitly listed to 2. The level goes from -1 (silent) to 4 (all the
things).

I see quite a lot of modules that I will not need. How do I configure /
disable them? -> Static plugin configuration is discouraged unless you
know what you’re doing. (Which I obviously don’t, yet).

`Quoting the introduction to strongswan <https://wiki.strongswan.org/projects/strongswan/wiki/IntroductionTostrongSwan#Routing>`__
strongswan is a keyring daemon that uses IKE to establish a security
association (SA) between two peers. IKE provides strong authentication
of both peers and derives unique cryptographic session keys. An IKE
session is often called IKE_SA in the docs. Besides authentication and
key material IKE also provides the means to exchange configuration
information (e.g., virtual IP addresses) and to negotiate IPsec SAs
(often called CHILD_SA). IPsec SAs (CHILD_SA) defines which network
traffic is to be secured and how it has to be encrypted and
authenticated. A CHILD_SA consists of two components:

-  the actual IPsec SAs (two for each direction) that describe
   algorithms to encrypt/authenticate traffic
-  policies that define which network traffic shall use such an SA

Policies are derived from the traffic selectors (TS) negotiated via IKE
when establishing a CHILD_SA. strongswan installs the negotiated IPsec
SAs and SPs into the kernel by using a platform dependent kernel API.

Connections and CHILD_SAs defined in swanctl.conf can be started on
three different occasions:

-  on traffic (if start_action=trap)
-  on startup (if start_action=start). The CHILD_SAs will not be
   restarted automatically when they go down. Other configuration
   settings are needed. This is not recommended. The user is encouraged
   to use trap policies instead (see above)
-  Manually (no start_action is provided). Use swanctl –initiate –child
   to start a connection

Possible values for (CHILD) SA proposals can be found
`here <https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2CipherSuites>`__.

Forward traffic
---------------

``remote_ts`` on Initiator sides basically claims which subnet ranges
can be reached via this IPsec connection. The gateway is already
configured to forward wireguard traffic (NAT). Wireguard traffic arrives
over the ``wg`` interface which makes it easy to identify. A quickfix to
also forward IPsec traffic is to add a rule that looks something like
this:

::

   iifname $wan ip saddr 10.3.0.0/24 oifname $wan ct state new counter accept;

``10.3.0.0/24`` is the virtual IP pool out of which an IP was assigned
to the Initiator. This doesn’t cut, though, because coming from that
subnet is only a symptom. What I actually want is to forward decrypted
payloads.

nft >= 0.9.1 knows ``meta ipsec exists``, nft >= 0.8.2 knows
``meta secpath exists``. Both apparently detect IPsec traffic.
Consequently the rule above becomes:

::

   meta secpath exists iifname $wan ip saddr 10.3.0.0/24 oifname $wan ct state new counter accept;

Failover
--------

Disclaimer: I have no idea about the details here and if what I’m doing
is sensible.

strongswan comes with builtin feature for load-balancing and failover.
However, they sounded a bit limiting so we try to stick to our
established keepalived/gateway setup. Note: DPD means “Dead Peer
Detection”. strongswan offers the actions ``clear``, ``restart`` and
``trap`` for ``dpd_action``. ``restart``, well, restarts the connection
for the CHILD_SA on a timeout. ``dpd_delay`` must not be equal to 0 to
trigger the sending of “Informational” packets that check the
reachability of the peer.

The test scenario was as follows: the roadwarrior continuosly pings a
node in the private network. By starting or stopping keepalived
(depending on the node and its priority) we simulate the loss of a
gateway. It as expected that the pings stop reaching their targets for a
period of time. The failover is considered to be successful if the IPsec
tunnel is re-established automatically and traffic passes again between
roadwarrior and the node. After the first failover, there should be
another failover to the “original” gateway.

Debugging
---------

By default, strongswan uses policy based routing. Entries are injected
into table 220.

-  To see all routing tables: ``ip rule list``
-  To see
   all routing rule: ``ip route show table all``
-  To see a specific
   routing table: ``ip route show table <N>``

Inside the kernel, the IP framework ``xfrm`` is used to transform
packets (e.g., encrypting payloads). ``ip xfrm *`` to see things.

I don’t see any traffic when I initiate the connection with
``swanctl --initiate --child home``. The systemd log shows an error
message:

::

   sending packet: from 192.168.188.139[500] to 185.128.119.223[500] (240 bytes)
   error writing to socket: Network is unreachable

``tcpdump -venni any udp port 500 or port 4500`` does not show any
packets.

-> Issue was that 39 != 139. The whole thing was avoidable from the
start by not setting ``local_addrs`` to a fixed value (it defaults to
``%any``)

BGP
---

The problem statement: With the current setup a roadwarrior can reach
the gateway and all nodes beyond the gateway in their private net. The
gateway can contact the roadwarrior. But what if a node or a pod in the
private network wants to reach the roadwarrior (probably more
interesting in a site-to-site scenario)?

Bird should import routes from routing table ``220`` (ipsecs) into its
internal routing table. It should export those routes via BGP. The BGP
server of the CNI plugin should import them and expose them on the
nodes.

FIB is short for Forwarding Information Base.

Kernel protocol is to exchange routes between a BIRD routing table and a
kernel routing table (FIB). Instances of kernel protocol cannot share
BIRD routing tables or FIBs. Use Pipe for that purpose.

Example:

.. code:: shell

   # Table to collect all IPv4 routes
   ipv4 table bgp_v4tab;

   # In bgp_v4tab, import all routes from master4
   protocol pipe {
       table bgp_v4tab;
       peer table master4;

Random notes from Jonas
-----------------------

-  On debian, I had to install ``strongswan-pki`` and
   ``strongswan-swanctl``.
-  You can use ``swanctl --load-all`` to (re-)load config etc
-  ``EAP_IDENTITY not supported, sending EAP_NAK`` -> You also need
   lib{charon,strongswan}-extra-plugins installed, may need restart of
   strongswan-starter to apply
-  ``ipsec_subnet`` should be set to the K8s subnet methinks?? or at
   least not defaulted to some strange range…

Additional info on the usage in the LCM
---------------------------------------

-  IPsec is a customer-specific solution and should remain so, i.e., we
   only support what was required.
-  One example of that is the authentication means. We only support PSK
   here

Upload an IPSec EAP PSK to Vault
--------------------------------

If you want to use IPSec, you have to upload the
pre-shared key to vault before triggering the LCM.
This can be done with the following command:

.. note::

   A root token is needed!
   The ``orchestrator`` role does not have enough privileges.

.. code:: shell

   # Please substitute CLUSTERNAME & YOUR_IPSEC_EAP_PSK
   vault kv put yaook/CLUSTERNAME/kv/ipsec-eap-psk ipsec_eap_psk=YOUR_IPSEC_EAP_PSK
