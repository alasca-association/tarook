### Pre-requisites

 - openstack project&user is created
 - openrc is loaded
 - gitlab ssh access

- Ansible 2.9+ (you can use requirements.txt to install it)
- Python OpenStack client
- GNU Make
- [jsonnet](https://github.com/google/jsonnet)
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install)
- terraform: https://www.terraform.io/downloads.html
  - move binary file to /usr/local/bin
  - sudo chmod +x if necessary
- sponge (apt install moreutils)
- toml
- wireguard
- current kernel headers:
  - uname -r
  - sudo apt-get install linux-headers-<..>

### Wireguard Hints:
- umask 0077 (to prevent the key from becoming world-readable)
- wg genkey > wg.key
- cat wg.key | wg pubkey
- add the public key to config.toml 
- wg-quick up ~/.wireguard/wg0.conf 

### HowTo:
- create a git Repo
- clone the git Repo
- copy the `managed-k8s/jenkins/env.template.sh` to the repo and rename it to `env.sh` and adjust it
- create the folder `config` inside the Repo
- copy the `managed-k8s/jenkins/config.template.toml` as `config.toml` to the `config` folder and adjust it
- run `<path-to-managed-k8s>/jenkins/manage_cluster.sh` for rollout of gitlab master state (calls `apply.sh` internally)
- alternatively, run `<path-to-managed-k8s>/actions/apply.sh` to use own changes
  - when using it for the first time and without having used `manage_cluster.sh` before, run `python3 managed-k8s/jenkins/toml_helper.py` first
### Hints:
- the folder structure should look like this:
 ```
 <cluster-repo>
 |- env.sh
 |- config/
 |-- config.toml
 ```
- maybe helpful: .envrc with
```
export KUBECONFIG="$(pwd)/inventory/.etc/admin.conf"   
source env.sh
```
- k8s gateways: `debian@<ip>`
   k8s master/worker: `ubuntu@<ip>`, only reachable via wireguard
- to add more ssh user, you have to add these lines in the config.toml
   ```
   [ansible.02_trampoline.group_vars.gateways]
    cah_users_include_users = ["<user>", "<user>"]
   
   [ansible.03_final.group_vars.all]
    cah_users_include_users = ["<user>", "<user>"]
   ``` 

### Documentation

The documentation is created with mkdocs [0] and located under docs/. 
 - To start the built-in dev-server, run `mkdocs serve -f mkdocs_<client|admin>.yml`
 - To compile the documentation to html, run `mkdocs build -f mkdocs_<client|admin>.yml`

[0] mkdocs.org


