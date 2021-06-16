# Wireguard

## Basic setup

1. Set the umask to something secure: ``umask 0077``
2. Create a private key: ``wg genkey > wg.key``
3. Calculate the public key: ``wg pubkey < wg.key > wg.pub``
4. Add the public key to the ``gateway.yaml`` inventory ``group_vars`` ``wg_peers`` section:

   ```yaml
   wg_peers:
   - pub_key: "your public key"
     ip: "ip/32 from wg_ip_cidr"
     ident: "some identifier for you, e.g firstnamelastname"
   ```
5. Run the ``02_trampoline`` stage
6. Copy ``inventories/.etc/wg_firstnamelastname.conf`` to ``wg0.conf``
7. Insert your private key into ``wg0.conf``
8. ``wg-quick up wg0.conf``
9. You should be able to ping instances now!

## Advanced: Wireguard based site-to-site tunnel

It is possible to let the LCM configure a tunnel to another mk8s cluster s.t. each peer can access both the pod and service network of the other side.
See the comments that accompany the fields in the `config.template.toml` - they ought to be self-explanatory.

(Current) limitations

- for obvious reasons the pod and service networks of the peers must not overlap
- one can only configure one peer (this is mostly a matter of turning the scalars into lists to extend)
- the k8s nodes still SNATs pod traffic, i.e., egress traffic originating from pods will get the node's IP
  - `kube-router` offers a flag (`--enable-pod-egress`) to disable the SNAT; other CNIs probably offer something similar
  - one would then have implement own iptables rules that do SNAT depending on the destination network (traffic into a peer's pod network would then not be SNATted)
  - changing this would require a bit of (potentially disruptive) work so I'm not sure if it's worth the hassle

### Internals

- additional wg tunnel (wg-peer1), only on VRRP master so we don't have conflicting connections where three gateways on one side simultaneously contact the other side
