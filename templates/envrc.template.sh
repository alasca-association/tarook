# Example .envrc file.
# shellcheck shell=bash

# For more details on existing environment variables and their effects,
# please see docs/admin/cluster-repo.md in the managed-k8s lcm
# repository.

# Passwordstore: Encrypt for C&H company members
export PASS_COMPANY_USERS=true

# Wireguard: Use wireguard on gateways (default: True)
export WG_USAGE=true

# Wireguard: Role out C&H company members
export WG_COMPANY_USERS=true

# Auto-configure C&H company members as users on the nodes
export SSH_COMPANY_USERS=true

# Wireguard: Interface and config file name
wg_conf_name='wg0'
export wg_conf_name

# Wireguard: Absolute path to your private wireguard key.
wg_private_key_file="$(pwd)/../privkey"
export wg_private_key_file

# Wireguard: Your username in the wg-user repository
wg_user='firstnamelastname'
export wg_user

# Terraform: Use Terraform (default: True)
export TF_USAGE=true

# OpenStack: Name of the keypair to use to bootstrap new instances.
# Does not affect existing instances.
TF_VAR_keypair='firstnamelastname-hostname-gendate'
export TF_VAR_keypair

# Optional: Useful to be able to interact with the cluster via kubectl.
KUBECONFIG="$(pwd)/inventory/.etc/admin.conf"
export KUBECONFIG

# Optional: activate the virtual env for managed-k8s
source_env ~/.venv/managed-k8s/bin/activate

# Optional: You can also source your openrc from here.
