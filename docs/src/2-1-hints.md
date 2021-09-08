# General Hints

<!-- TODO: needs updating with current LCM -->

- k8s gateways: `debian@<ip>`
- k8s master/worker: `ubuntu@<ip>`, only reachable via wireguard
- to add more ssh user, you have to add these lines in the config.toml

   ```
   [ansible.02_trampoline.group_vars.gateways]
    cah_users_include_users = ["<user>", "<user>"]

   [ansible.03_final.group_vars.all]
    cah_users_include_users = ["<user>", "<user>"]
   ```


## Auto-generated ssh-config

1. Write the output of `openstack server list -f json` into a file <servers>
2. Use utils/ssh_conf.py to auto-generate an ssh configuration file for the the cluster
3. Use it like `ssh -F <ssh_config> master-az1`. The configuration uses the private IPs of the servers. Wireguard must therefore be running.
4. Move <ssh_config> to the `.etc/` subdir in the `03_final` folder.
