# shellcheck shell=bash disable=SC2154,SC2034

cluster_repository="$(realpath ".")"
code_repository="$(realpath "$actions_dir/../")"
etc_directory="$(realpath "etc")"
config_file="$cluster_repository/config/config.toml"

submodule_managed_k8s_name="managed-k8s"

terraform_min_version="1.3.0"
terraform_state_dir="$cluster_repository/terraform"
terraform_module="${TERRAFORM_MODULE_PATH:-$code_repository/terraform}"
terraform_plan="$terraform_state_dir/plan.tfplan"
terraform_disruption_setting="terraform.prevent_disruption"

ansible_directory="$code_repository/ansible"

ansible_inventory_base="$cluster_repository/inventory/yaook-k8s"
ansible_inventory_host_file="$ansible_inventory_base/hosts"

ansible_k8s_core_dir="$code_repository/k8s-core/ansible"
ansible_k8s_supplements_dir="$code_repository/k8s-supplements/ansible"
ansible_k8s_custom_dispatch_dir="$code_repository/k8s-custom/ansible"
ansible_k8s_custom_playbook_dir="$cluster_repository/k8s-custom"
ansible_k8s_custom_playbook="$ansible_k8s_custom_playbook_dir/main.yaml"

ansible_k8s_sl_vars_base="$ansible_inventory_base/04_k8s_service_layer"
ansible_k8s_ms_vars_base="$ansible_inventory_base/05_k8s_managed_service"

vault_dir="${VAULT_DIR:-$cluster_repository/vault}"

if [ "${MANAGED_K8S_COLOR_OUTPUT:-}" = 'true' ]; then
    use_color='true'
elif [ "${MANAGED_K8S_COLOR_OUTPUT:-}" = 'false' ]; then
    use_color='false'
elif [ -t 1 ] || [ -t 2 ]; then
    use_color='true'
else
    use_color='false'
fi

function set_kubeconfig() {
    # Export KUBECONFIG if not already exported
    # Export with default if unset or empty
    if [[ -z "${KUBECONFIG:+x}" || ! "${KUBECONFIG@a}" == *x* ]]; then
        export KUBECONFIG="${KUBECONFIG:-$cluster_repository/etc/admin.conf}"
    fi
}

function load_vault_container_name() {
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
}

function load_conf_vars() {
    # All the things with side-effects should got here

    tf_usage=${tf_usage:-"$(tomlq '.terraform | if has ("enabled") then .enabled else true end' "$config_file")"}
    terraform_prevent_disruption="$(
        tomlq ".$terraform_disruption_setting"'
            | if (.|type)=="boolean" then . else error("unset-or-invalid") end' \
            "$config_file" 2>/dev/null
    )" || unset terraform_prevent_disruption  # unset when unset, invalid or file missing

    wg_usage=${wg_usage:-"$(tomlq '.wireguard | if has("enabled") then .enabled else true end' "$config_file")"}

    if [ "${wg_usage:-true}" == "true" ]; then
        wg_conf="${wg_conf:-$cluster_repository/${wg_conf_name}.conf}"
        wg_interface="$(basename "$wg_conf" | cut -d'.' -f1)"
        wg_endpoint="${wg_endpoint:-0}"
        ansible_wg_template="$etc_directory/wireguard/wg${wg_endpoint}/wg${wg_endpoint}_${wg_user}.conf"
    fi
}

function check_conf_sanity() {
    if ! (ansible-inventory -i "${ansible_inventory_base}" --host localhost \
            | jq --exit-status '.ipv4_enabled or .ipv6_enabled' &> /dev/null); then
        errorf "Neither IPv4 nor IPv6 are enabled."
        errorf "Enable at least one in your hosts file $ansible_inventory_host_file."
        exit 2
    fi
}

function color_enabled() {
    [ "$use_color" = 'true' ]
}

function ansible_disruption_allowed() {
    [ "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" = 'true' ]
}

function harbour_disruption_allowed() {
    load_conf_vars
    [ "${MANAGED_K8S_DISRUPT_THE_HARBOUR:-}" = 'true' ] \
 && [ "${tf_usage:-true}+${terraform_prevent_disruption:-true}" != 'true+true' ]
    # when Terraform is used also factor in its config
}

function require_ansible_disruption() {
    if ! ansible_disruption_allowed; then
        # shellcheck disable=SC2016
        errorf '$MANAGED_K8S_RELEASE_THE_KRAKEN is set to %q' "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" >&2
        errorf 'aborting since disruptive operations with Ansible are not allowed' >&2
        exit 3
    fi
}

function require_harbour_disruption() {
    load_conf_vars
    if ! harbour_disruption_allowed; then
        # shellcheck disable=SC2016
        errorf '$MANAGED_K8S_DISRUPT_THE_HARBOUR is set to %q' "${MANAGED_K8S_DISRUPT_THE_HARBOUR:-}" >&2
        if [ "${tf_usage:-true}" == 'true' ]; then
            if [ -z ${terraform_prevent_disruption+x} ]; then
                errorf "and ${terraform_disruption_setting} in ${config_file}"' is unset or invalid' >&2
            else
                errorf "and ${terraform_disruption_setting} in ${config_file}"' is set to %q' \
                       "${terraform_prevent_disruption}" >&2
            fi
        fi
        errorf 'aborting since disruptive operations on the harbour infra are not allowed' >&2
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

function check_vault_token_policy() {
    if (vault token lookup -format=json | jq --exit-status 'any(.data.policies[] | contains("root", "yaook/orchestrator"); .)' &> /dev/null); then
        return
    fi
    errorf 'Your vault token has insufficient policies for a KUBECONFIG generation'
    errorf 'The token must either be a root token or have the "yaook/orchestrator" policy'
    exit 2
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

    if ansible_disruption_allowed; then
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

function install_prerequisites() {
    # Install ansible galaxy requirements
    ansible-galaxy install -r "$ansible_directory/requirements.yaml"
}

function check_venv() {
    if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
        errorf 'MINIMAL_ACCESS_VENV is set to true.'
        errorf 'With that, the venv is not sufficient for usage of the LCM.'
        errorf 'Set it to false and reload your environment.'
        exit 1
    fi
}

function tf_init_http () {
    run terraform -chdir="$terraform_module" init \
                  -upgrade \
                  -backend-config="address=$backend_address" \
                  -backend-config="lock_address=$backend_address/lock" \
                  -backend-config="unlock_address=$backend_address/lock" \
                  -backend-config="lock_method=POST" \
                  -backend-config="unlock_method=DELETE" \
                  -backend-config="retry_wait_min=5"
}

function tf_init_local () {
    run terraform -chdir="$terraform_module" init \
                  -upgrade
}
