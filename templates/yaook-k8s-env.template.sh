# Example file for ~/.config/yaook-k8s/env
# shellcheck shell=bash

# If you only manage one cluster or use different keys per cluster
# then put this in your .envrc.local instead

# For more details on existing environment variables and their effects,
# please see docs/admin/cluster-repo.md in the managed-k8s lcm
# repository.

# Wireguard: Absolute path to your private wireguard key.
export wg_private_key_file="path/to/your/private/key"
# Alternatively you can directly export your wireguard key
#export wg_private_key="$(pass PASS_PATH_TO_YOUR_WIREGUARD_KEY)"

# Wireguard: Your username in the wg-user repository
export wg_user='firstnamelastname'

# Wireguard: MTU value
# Optional parameter, usually Wireguard handles this correctly automatically
#wg_mtu='1400'
#export wg_mtu

# OpenStack: Name of the keypair to use to bootstrap new instances.
# Does not affect existing instances.
export TF_VAR_keypair='firstnamelastname-hostname-gendate'

# Optional: You can also source your openrc from here.

# Optional: activate the virtual env for yaook-k8s
source_env_if_exists ~/.venv/yaook-k8s/bin/activate

