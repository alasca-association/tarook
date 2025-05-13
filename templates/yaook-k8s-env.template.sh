# Example file for ~/.config/yaook-k8s/env
# shellcheck shell=bash

# If you only manage one cluster or use different keys per cluster
# then put this in your .envrc.local instead

# For more details on existing environment variables and their effects,
# please see docs/admin/cluster-repo.md in the managed-k8s lcm
# repository.

# Optional: Setup a minimal venv for Kubernetes API access only
# instead of a full blown user and development environment.
# Note that this can instead be set in ".envrc.local" for specific clusters.
#export MINIMAL_ACCESS_VENV=true

# Specify a command to retrieve the wireguard private key from a safe place
# Note that the command is called with an empty environment, so any variables
# that it may need, have to be specified explicitly.
#export wg_private_key_command='PASSWORD_STORE_DIR="'"$PASSWORD_STORE_DIR"'" pass my-wg-key'

# Wireguard: Your username in the wg-user repository
export wg_user='firstnamelastname'

# Wireguard: MTU value
# Optional parameter, usually Wireguard handles this correctly automatically
#wg_mtu='1400'
#export wg_mtu

# OpenStack: Name of the keypair to use to bootstrap new instances.
# Does not affect existing instances.
export TF_VAR_keypair='firstnamelastname-hostname-gendate'

# Set to true if you are using rootless docker or podman
#VAULT_IN_DOCKER_USE_ROOTLESS=true

# Terraform backup on Gitlab: To store the state remotely in a gitlab repo,
# Gitlab username and Gitlab token must be configured here.
# The token needs API scope and at least maintainer permissions.
#export TF_HTTP_USERNAME="<gitlab-username>"
#export TF_HTTP_PASSWORD="<gitlab-access-token>"

# Optional: You can also source your openrc from here.

# Which dependency group should be loaded into your devShell
# Possible values can be found in nix/dependencies.nix
# 'dev' is recommended if you do development work on Tarook
# 'interactive' is recommended if you are on NixOS
#export YAOOK_K8S_DEVSHELL="dev"

# Set locale for Ansible if not yet present
#[[ -z ${LC_ALL} ]] && { export LC_ALL=C.UTF-8 ; }
