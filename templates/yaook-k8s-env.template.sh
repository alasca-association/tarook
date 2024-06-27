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

# Set to true if you are using rootless docker or podman
#VAULT_IN_DOCKER_USE_ROOTLESS=true

# Terraform backup on Gitlab: To store the state remotely in a gitlab repo,
# Gitlab username and Gitlab token must be configured here.
# The token needs API scope and at least maintainer permissions.
#export TF_HTTP_USERNAME="<gitlab-username>"
#export TF_HTTP_PASSWORD="<gitlab-access-token>"

# Optional: You can also source your openrc from here.

# If you want to load the optional interactive dependencies into your devShell
# Recommended if you're on NixOS. Not recommended on Debian et al.
# export YAOOK_K8S_DEVSHELL="withInteractive"

# There is a bug in poetry that makes it access the user's key ring
# even if not necessary. It should only do that (1) when publishing
# or (2) when using dependencies from private repositories.
# This can lead to problems when the key ring is not available or
# is password protected. Setting the following variable avoids that.
# See https://github.com/python-poetry/poetry/issues/1917
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

# Set locale for Ansible if not yet present
#[[ -z ${LC_ALL} ]] && { export LC_ALL=C.UTF-8 ; }
