# FAQ and Troubleshooting

## FAQ - Frequently Asked Questions

### "How do I ssh into my cluster nodes?"

```console
$ ssh -i <path to private key> -o UserKnownHostsFile=<path to known hosts file> <username>@<ip address>
```

- **`<path to private key>`**
    - This should be the path to your private key matching the keypair specified by the environment variable `TF_VAR_keypair`.
- **`<path to known hosts file>`**
    - This should be the path to the cluster specific known hosts file.
      The known hosts file is managed by the LCM.
      It is located in your cluster specific inventory at `$(pwd)/inventory/.etc/ssh_known_hosts`.
- **`<username>`**
    - This should be the default user of the image you are deploying.
    - By default this is `debian` for the gateway nodes and `ubuntu` for the master and worker nodes.
        - This setting can be changed in `./terraform/00-variables.tf`.
- **`<ip address>`**
    - The gateway, worker and master nodes are all connected in a private network and all have unique private IP addresses. Additionally all gateway nodes are given floating IP addresses.
    - When ssh-ing to one of the gateways you can either use its floating or its private IP address.
    - Master and worker nodes are only accessible using their private IP addresses and the traffic to these nodes is always (transparently) routed via the gateway nodes.
    - The use of a private IP address requires first setting up the wireguard tunnel.
        - If it is not already up, you can set it up by running the [`wg-up.sh`](./operation/actions-references.md#wg-upsh) script.
            ```console
            $ ./managed-k8s/actions/wg-up.sh
            ```

> ***Note:*** Under normal circumstances, the host key of a node is not expected to change.
> However, you can enforce allowing host key changes by passing `-e allow_host_key_changes=true` (via [AFLAGS](./usage/environmental-variables.html#behavior-altering-variables).

### "How can I test my yk8s-Cluster?"

We recommend testing whether your cluster was successfully deployed by [manually logging into the nodes](#how-do-i-ssh-into-my-cluster-nodes) and/or by running:
```console
./managed-k8s/actions/test.sh
```

### "How can I delete my yk8s-Cluster?"

You can delete the yk8s-Cluster and all associated OpenStack resources by triggering
the [`destroy.sh`](./operation/actions-references.md#destroysh) script.

> ***Warning:*** Destroying a cluster cannot be undone.

> ***Note:*** The [configuration](./usage/cluster-configuration.md) of the cluster is neither deleted nor reset.

```console
# Destroy the yk8s cluster and delete all OpenStack resources
$ MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8S_NUKE_FROM_ORBIT=true ./managed-k8s/actions/destroy.sh
```

## Troubleshooting

### "The `apply.sh` script cannot connect to the host nodes"

**Error message:** `failed to detect a valid login!`
- First make sure you can [manually connect to the host nodes](#how-do-i-ssh-into-my-cluster-nodes).
- You may need to explicitly specify which key Ansible shall use for connections, i.e. the private key file corresponding to the OpenStack key pair specified by the environment variable `TF_VAR_keypair` in `./.envrc`.
    - You can do this either
        - in your [Ansible configuration file](./usage/cluster-configuration.md#ansible-configuration) `./managed-k8s/ansible/ansible.cfg` (recommended):
             ```console
             ...
             [defaults]
             private_key_file = /path/to/private_key_file
             ...
             ```
        - or by setting the variable `ansible_ssh_private_key_file` on the command line via [the `AFLAGS` environment variable](./usage/environmental-variables.md#behavior-altering-variables):
             ```console
             AFLAGS='-e ansible_ssh_private_key_file=/path/to/private_key_file' ./managed-k8s/actions/apply.sh
             ```
    - Further information is available [in the upstream documentation on Ansible connections](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html).

### "The wg_gw_key does not seem to be in the passwordstore"

**Error message:** `passwordstore: passname wg_gw_key not found and missing`, `Command ''[''pass'', ''show'', ''wg_gw_key'']'' returned non-zero exit status 2.` or `NO MORE HOSTS LEFT`

- Did you step away from your desk and missed the prompt to enter the passphrase for your gpg key?

### "My private wireguard key cannot be found"

**Error message:** `cat: '~/.wireguard/wg.key': No such file or directory`

- Use an absolute path to specify the `wg_private_key_file` environment variable in `./.envrc`.

### "I can't ssh into my cluster nodes"

- Follow the instuctions on [how to connect to the cluster via ssh](#how-do-i-ssh-into-my-cluster-nodes).
- Ensure that your ssh key is in [a supported format](./usage/initialization.md#appendix).

### The `Get certificate information task` of the `k8s-master` fails

- The exact error: `AttributeError: 'builtins.Certificate' object has no attribute '_backend'`
- Remove your local Ansible directory but make sure to not remove data you still need so make backup in case (e.g. `mv ~/.ansible ~/.ansible.bak`)
- https://gitlab.com/yaook/k8s/-/issues/441
