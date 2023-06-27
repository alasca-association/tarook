# shellcheck shell=bash disable=SC2154,SC2034
cluster_repository="$(realpath ".")"
code_repository="$(realpath "$actions_dir/../")"

terraform_min_version="0.14.0"
terraform_state_dir="$cluster_repository/terraform"
terraform_module="${TERRAFORM_MODULE_PATH:-$code_repository/terraform}"
terraform_plan="$terraform_state_dir/plan.tfplan"
ansible_directory="$code_repository/ansible"

ansible_k8s_base_playbook="$code_repository/k8s-base"
ansible_k8s_sl_playbook="$code_repository/k8s-service-layer"
ansible_k8s_ms_playbook="$code_repository/k8s-managed-services"
ansible_k8s_custom_playbook="$cluster_repository/k8s-custom"
ansible_inventory_template="$ansible_k8s_base_playbook/inventories/terraform"
ansible_inventory_base="$cluster_repository/inventory"
ansible_inventoryfile_02="$ansible_inventory_base/02_trampoline/hosts"
ansible_inventoryfile_03="$ansible_inventory_base/03_k8s_base/hosts"
ansible_inventoryfile_custom="$ansible_inventory_base/99_custom/hosts"
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
    ansible_wg_template="$ansible_inventory_base/.etc/wireguard/wg_${wg_user}.conf"
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
