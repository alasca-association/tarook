# shellcheck shell=bash disable=SC2154,SC2034

# Set kubeconfig
cluster_repository="$(realpath ".")"
code_repository="$(realpath "$actions_dir/../")"
etc_directory="$(realpath "etc")"

export KUBECONFIG="$cluster_repository/etc/admin.conf"

submodule_managed_k8s_name="managed-k8s"

terraform_min_version="0.14.0"
terraform_state_dir="$cluster_repository/terraform"
terraform_module="${TERRAFORM_MODULE_PATH:-$code_repository/terraform}"
terraform_plan="$terraform_state_dir/plan.tfplan"
ansible_directory="$code_repository/ansible"

ansible_inventory_base="$cluster_repository/inventory/yaook-k8s/"
ansible_inventory_host_file="$ansible_inventory_base/hosts"

ansible_k8s_core_dir="$code_repository/k8s-core/ansible"
ansible_k8s_supplements_dir="$code_repository/k8s-supplements/ansible"
ansible_k8s_custom_playbook="$cluster_repository/k8s-custom"

ansible_k8s_sl_vars_base="$ansible_inventory_base/04_k8s_service_layer"
ansible_k8s_ms_vars_base="$ansible_inventory_base/05_k8s_managed_service"

vault_dir="${VAULT_DIR:-$cluster_repository/vault}"

# We assign to each repository a unique container name. We need to have
# different container names per repository in order to ensure that a dev can
# run multiple vault instances in parallel and without conflict *and* that the
# data is still located in the corresponding repository for committing with
# git.
# While the latter is not strictly sensible for development, we'll need this
# during executing the upgrade path from pass to Vault.
if [ -e "$vault_dir/container-name" ]; then
    vault_container_name="$(cat "$vault_dir/container-name")"
else
    mkdir -p "$vault_dir"
    vault_container_name="yaook-vault-$(uuidgen --random | cut -d'-' -f1-3)"
    echo "$vault_container_name" > "$vault_dir/container-name"
fi

if [ "${WG_USAGE:-true}" == "true" ]; then
    wg_conf="${wg_conf:-$cluster_repository/${wg_conf_name}.conf}"
    wg_interface="$(basename "$wg_conf" | cut -d'.' -f1)"
    wg_endpoint="${wg_endpoint:-0}"
    ansible_wg_template="$etc_directory/wireguard/wg${wg_endpoint}/wg${wg_endpoint}_${wg_user}.conf"
fi

if [ "${MANAGED_K8S_COLOR_OUTPUT:-}" = 'true' ]; then
    use_color='true'
elif [ "${MANAGED_K8S_COLOR_OUTPUT:-}" = 'false' ]; then
    use_color='false'
elif [ -t 1 ] || [ -t 2 ]; then
    use_color='true'
else
    use_color='false'
fi

function color_enabled() {
    [ "$use_color" = 'true' ]
}

function disruption_allowed() {
    [ "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" = 'true' ]
}

function require_disruption() {
    if ! disruption_allowed; then
        # shellcheck disable=SC2016
        errorf '$MANAGED_K8S_RELEASE_THE_KRAKEN is set to %q' "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" >&2
        errorf 'aborting since disruptive operations are not allowed' >&2
        exit 3
    fi
}

function require_vault_token() {
    if [ -z ${VAULT_TOKEN+x} ]; then
        # shellcheck disable=SC2016
        errorf '$VAULT_TOKEN is not set but required during this stage'
        exit 1
    fi
}

function ccode() {
    if ! color_enabled; then
        return
    fi
    # shellcheck disable=SC2059
    printf "$@"
}

function log() {
    level="$1"
    shift
    colorcode="$1"
    shift
    fmt="$1"
    shift
    printf "%s%s:%s $fmt\n" "$(ccode "$colorcode")" "$level" "$(ccode '\x1b[0m')" "$@"
}

function errorf() {
    log 'error' '\x1b[1;31m' "$@"
}

function warningf() {
    log 'warning' '\x1b[1;33m' "$@"
}

function hintf() {
    log 'hint' '\x1b[1m' "$@"
}

function notef() {
    log 'note' '\x1b[1m' "$@"
}

function run() {
    cmd="$1"
    shift
    printf '\n'
    ccode '\x1b[1;92m'
    printf '$ '
    ccode '\x1b[0m\x1b[1m'
    printf '%q' "$cmd"
    ccode '\x1b[0m'
    for arg; do
        printf ' %q' "$arg"
    done
    printf '\n\n'
    "$cmd" "$@"
}

function validate_wireguard() {
    if [ -z "${wg_user:-}" ]; then
        # shellcheck disable=SC2016
        errorf '$wg_user must be set' >&2
        exit 2
    fi
    if [ -z "${wg_private_key:-}" ] && [ -z "${wg_private_key_file:-}" ]; then
        # shellcheck disable=SC2016
        errorf 'Either $wg_private_key or $wg_private_key_file must be set' >&2
        exit 2
    fi
}

function ansible_playbook() {
    ansible_flags="${AFLAGS:---diff -f42}"

    if disruption_allowed; then
        warningf 'allowing ansible to perform disruptive actions' >&2
        # shellcheck disable=SC2016
        warningf 'approval was given by setting $MANAGED_K8S_RELEASE_THE_KRAKEN' >&2
        ansible_flags="${ansible_flags} --extra-vars release_the_kraken=true"
    fi

    # shellcheck disable=SC2086
    (export ANSIBLE_CONFIG="$ansible_directory/ansible.cfg" && run ansible-playbook $ansible_flags "$@")
}

function load_gitlab_vars() {
    gitlab_base_url="$(jq -r .gitlab_base_url   "$terraform_state_dir/config.tfvars.json")"
    gitlab_project_id="$(jq -r .gitlab_project_id "$terraform_state_dir/config.tfvars.json")"
    gitlab_state_name="$(jq -r .gitlab_state_name "$terraform_state_dir/config.tfvars.json")"
    backend_address="$gitlab_base_url/api/v4/projects/$gitlab_project_id/terraform/state/$gitlab_state_name"
}

# true: HTTP/200 response; false: HTTP/404; exit: HTTP/*
function check_return_code () {
    local gitlab_response="$1"
    if [ "$gitlab_response" == "200" ]; then
        return 0
    elif [ "$gitlab_response" == "404" ]; then
        return 1
    elif [ "$gitlab_response" == "401" ]; then
        echo
        notef "HTTP 401. The provided GitLab credentials seem to be invalid."
        exit 2
    else
        echo
        notef "Unexpected HTTP response: $gitlab_response"
        exit 1
    fi
}
