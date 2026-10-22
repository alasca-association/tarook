NetBird
=======

Tarook can deploy a self-hosted `NetBird <https://netbird.io>`__ server into the 
cluster and automatically pre-provision it to be ready for use.

Architecture
------------

- The combined ``netbird server`` runs as a single replica on the control plane.
  Its SQLite databases live on a ``ReadWriteOnce`` volume.
  The volume can move between nodes, so no database HA is needed.
- The NetBird dashboard runs next to the server.
- HTTPS is exposed through a dedicated Gateway of the envoy-gateway, 
  with a certificate provided by cert-manager. (Requires Tarook v15.0)

Requirements
------------

- :ref:`configuration-options.yk8s.k8s-service-layer.envoy-gateway.enabled` and
  :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager.enabled`
- A cert-manager Issuer that can issue certificates for the netbird domain
- Vault holds the secrets netbird produces, so the orchecstrator needs access to ``kv/data/netbird``.
- A DNS record for the domain pointing to the address of the NetBird Gateway.
- UDP port 3478 must be reachable for NetBird to allow STUN.

Sample config
-------------


.. code:: nix

   {
     # This is just a sample and does not yet reflect an actual configuration.
     yk8s.k8s-service-layer.netbird = {
       enabled = true;
       domain = "customer.netbird.cloudandheat.com";
       customer_name = "name";
       owner_email = "admin@cloudandheat.com";
       issuer_name = "letsencrypt"; # perhaps?

       # some grouping for k8s-nodes
       groups = ["k8s-nodes"];
       setup_keys = [
          {
            name = "k8s-nodes";
            auto_groups = ["k8s-nodes"];
            expires_in = 99999999;
          }
        ];
       policies = [
         {
           name = "nodes";
           rules = [
             {
               name = "nodes-to-nodes"; # something like that
               sources = ["k8s-nodes"];
               destinations = ["k8s-nodes"];
             }
           ];
         };
       ];
     };
   };  


Bootstrapping and secrets
-------------------------

On the first run, Ansible should:

#. generate the store encryption key, the relay secret, the session key and the owner password. Then store them in Vault.
#. deploy NetBird without exposing it to the internet so no unauthenticated ``/api/setup`` endpoint can be called
#. deploy a short lived pod to call ``/api/setup`` from internal cluster and create the owner account as well as a one-day setup token.
#. use the setup-token to create ``tarook-automation`` service user and its token, stores that in vault and deletes the setup token.
#. create the Gateway and apply the configured groups, setup keys and policies.



   
