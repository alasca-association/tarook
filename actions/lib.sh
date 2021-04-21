# shellcheck shell=bash disable=SC2154,SC2034
cluster_repository="$(realpath ".")"
code_repository="$(realpath "$actions_dir/../")"

terraform_state_dir="$cluster_repository/terraform"
terraform_module="$code_repository/terraform"
terraform_plan="$terraform_state_dir/plan.tfplan"
ansible_playbook="$code_repository/ansible"
ansible_inventory_template="$ansible_playbook/inventories/terraform"
ansible_inventory_base="$cluster_repository/inventory"
ansible_inventoryfile_02="$ansible_inventory_base/02_trampoline/hosts"
ansible_inventoryfile_03="$ansible_inventory_base/03_final/hosts"

wg_conf="${wg_conf:-$cluster_repository/$wg_conf_name.conf}"
wg_interface="$(basename "$wg_conf" | cut -d'.' -f1)"
ansible_wg_template="$ansible_inventory_base/.etc/wg_${wg_user}.conf"


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
    run ansible-playbook $ansible_flags "$@"
}
