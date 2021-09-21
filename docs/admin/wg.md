# Wireguard setup

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
