# Example .envrc file.
# shellcheck shell=bash

# For more details on existing environment variables and their effects,
# please see docs/admin/cluster-repo.md in the managed-k8s lcm
# repository.

# Wireguard: Interface and config file name
wg_conf_name='wg0'
export wg_conf_name

# Wireguard: Absolute path to your private wireguard key.
wg_private_key_file="$(pwd)/../privkey"
export wg_private_key_file

# Wireguard: Your username in the wg-user repository
wg_user='firstnamelastname'
export wg_user

# OpenStack: Name of the keypair to use to bootstrap new instances.
# Does not affect existing instances.
TF_VAR_keypair='firstnamelastname-hostname-gendate'
export TF_VAR_keypair

# Optional: Useful to be able to interact with the cluster via kubectl.
KUBECONFIG="$(pwd)/inventory/.etc/admin.conf"
export KUBECONFIG

# Optional: You can also source your openrc from here.
