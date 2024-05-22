# Example .envrc file.
# shellcheck shell=bash

# This file is meant to be checked into the VCS and to contain
# environment variables specific to the cluster and shared
# between users.

# User specific variables are read from 3 locations.
#
#   1. ~/.config/yaook-k8s/env
#   2. the next .envrc in parent directories
#      (via source_up)
#   3. .envrc.local
#
# The first can contain user specific variables
# that apply to all clusters.
# The second can be used to target subsets of
# clusters.
# The third is for user and cluster specific
# variables and is sourced in the end of this .envrc
# so it can override variables.

source_env ~/.config/yaook-k8s/env || true
source_up || true
# For up-to-date direnv versions one can also use:
# https://direnv.net/man/direnv-stdlib.1.html#codesourceenvifexists-ltfilenamegtcode
#source_env_if_exists ~/.config/yaook-k8s/env
# https://direnv.net/man/direnv-stdlib.1.html#codesourceupifexists-ltfilenamegtcode
#source_up_if_exists

source_env "$PWD/.envrc.local" || true
# For up-to-date direnv versions one can also use:
# https://direnv.net/man/direnv-stdlib.1.html#codesourceenvifexists-ltfilenamegtcode
#source_env_if_exists "$PWD/.envrc.local"

source_env ./managed-k8s/.envrc.lib.sh || true
use flake_if_nix ./managed-k8s
layout poetry ./managed-k8s

# For more details on existing environment variables and their effects,
# please see docs/admin/cluster-repo.md in the managed-k8s lcm
# repository.

# Wireguard: Role out C&H company members
export WG_COMPANY_USERS=false

# Wireguard: Interface and config file name
wg_conf_name='wg0'
export wg_conf_name

# Specifies which wireguard endpoint to use as client
export wg_endpoint=0

# Optional: Vault: Activate Hashicorp Vault Docker container
export USE_VAULT_IN_DOCKER=false

# These should be set according to your org and country. This will be used to
# provision root and/or intermediate CAs depending on which workflow you chose.
# It is irrelevant for development/testing setups, but you should probably get
# this right for productive setups in order to avoid any confusion.
#export YAOOK_K8S_CA_ORGANIZATION_OVERRIDE='Your Company Ltd.'
#export YAOOK_K8S_CA_COUNTRY_OVERRIDE='XX'

# Vault: Define Vault data storage path
#VAULT_DIR="$(pwd)/vault"
#export VAULT_DIR

# Vault: Env var script for the Vault docker instance
# Resource your envrc.sh file again after you've started Vault,
# to source Vault related information, like VAULT_ADDR, VAULT_ROOT_TOKEN
#source "$(pwd)/managed-k8s/actions/vault_env.sh"

# Optional: Useful to be able to interact with the cluster via kubectl.
KUBECONFIG="$(pwd)/etc/admin.conf"
export KUBECONFIG

# Optional: Use custom roles that can be dropped into the
# 'cluster_repository/k8s-custom' folder and executed after
# after initialization through the included main.yaml
export K8S_CUSTOM_STAGE_USAGE=true

# Optional: Set this variable to false to init new clusters with the newest commit
# on the default (devel) branch instead of the latest release.
# export MANAGED_K8S_LATEST_RELEASE=false

if [ -f "$KUBECONFIG" ] && ! yq -r '.users[0].user."client-certificate-data"' "$KUBECONFIG" | base64 -d | openssl x509 -checkend 186400 -noout >/dev/null; then
  echo "======="
  echo "WARNING: Your kubeconfig is expired or will expire within the next 24h. Please run ./managed-k8s/actions/k8s-login.sh to renew it"
  echo "======="
fi
