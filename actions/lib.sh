# shellcheck shell=bash disable=SC2154,SC2034

cluster_repository="$(realpath ".")"
code_repository="$(realpath "$actions_dir/../")"
etc_directory="$(realpath "etc")"
group_vars_dir="${cluster_repository}/inventory/yaook-k8s/group_vars"
conf_vars_file="${cluster_repository}/inventory/conf_vars/main.yaml"
state_dir="$cluster_repository/state"

release_migration_lock="$state_dir/release-migration-in-progress"

version_major_minor=$(grep -Po '^[0-9]+\.[0-9]+' "$code_repository/version")

submodule_managed_k8s_name="managed-k8s"

terraform_min_version="1.3.0"
terraform_state_dir="$state_dir/terraform"
terraform_disruption_lock="$terraform_state_dir/prevent_disruption.lock"
export TF_DATA_DIR="$terraform_state_dir/.terraform"
terraform_module="${TERRAFORM_MODULE_PATH:-$code_repository/terraform}"
terraform_plan="$terraform_state_dir/plan.tfplan"

ansible_directory="$code_repository/ansible"

ansible_inventory_base="$cluster_repository/inventory/yaook-k8s"
ansible_inventory_host_file="$ansible_inventory_base/hosts"

ansible_k8s_core_dir="$code_repository/k8s-core/ansible"
ansible_k8s_supplements_dir="$code_repository/k8s-supplements/ansible"
ansible_k8s_custom_dispatch_dir="$code_repository/k8s-custom/ansible"
ansible_k8s_custom_playbook_dir="$cluster_repository/k8s-custom"
ansible_k8s_custom_playbook="$ansible_k8s_custom_playbook_dir/main.yaml"
ansible_k8s_custom_inventory="$cluster_repository/k8s-custom/inventory"

vault_dir="${VAULT_DIR:-$state_dir/vault}"

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
    # All the things with side-effects should go here

    terraform_prevent_disruption="$(if [ -e "$terraform_disruption_lock" ]; then echo "true"; else echo "false"; fi)"
    tf_usage="$(yq '.tf_usage' "$conf_vars_file")"
    wg_usage="$(yq '.wg_usage' "$conf_vars_file")"

    if [ "${wg_usage:-true}" == "true" ]; then
        wg_conf="${wg_conf:-$cluster_repository/${wg_conf_name}.conf}"
        wg_interface="$(basename "$wg_conf" | cut -d'.' -f1)"
        wg_endpoint="${wg_endpoint:-0}"
        ansible_wg_template="$etc_directory/wireguard/wg${wg_endpoint}/wg${wg_endpoint}_${wg_user}.conf"
        wg_subnet="$(yq -r .wg_subnet "$conf_vars_file")"
        wg_subnet_v6="$(yq -r .wg_subnet_v6 "$conf_vars_file")"
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
        if [ "${MANAGED_K8S_DISRUPT_THE_HARBOUR:-}" != 'true' ]; then
            # shellcheck disable=SC2016
            errorf '$MANAGED_K8S_DISRUPT_THE_HARBOUR is set to %q. Set to "true" to allow disruption.' "${MANAGED_K8S_DISRUPT_THE_HARBOUR:-}" >&2
        fi
        if [ "${tf_usage:-true}" == 'true' ]; then
            if [ "${terraform_prevent_disruption}" = "true" ]; then
              errorf "The lockfile $terraform_disruption_lock exists. Delete it to allow disruption."
            fi
        fi
        errorf 'Aborting since disruptive operations on the harbour infra are not allowed' >&2
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
    1>&2 printf "%s%s:%s $fmt\n" "$(ccode "$colorcode")" "$level" "$(ccode '\x1b[0m')" "$@"
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
    if [ -z "${wg_private_key_command:-}" ] && [ -z "${wg_private_key:-}" ] && [ -z "${wg_private_key_file:-}" ]; then
        # shellcheck disable=SC2016
        errorf 'Either $wg_private_key_command or $wg_private_key or $wg_private_key_file must be set' >&2
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

function check_release_migration_lock() {
    if [[ -e "$release_migration_lock" ]] && [[ "${IGNORE_MIGRATION_LOCK:-false}" != "true" ]]; then
        errorf "Ongoing release migration detected. Refusing to continue."
        errorf "Please complete the release migration process by running migrate-to-release.sh"
        exit 1
    fi
}

function check_venv() {
    if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
        errorf 'MINIMAL_ACCESS_VENV is set to true.'
        errorf 'With that, the venv is not sufficient for usage of the LCM.'
        errorf 'Set it to false and reload your environment.'
        exit 1
    fi
}

function tf_init() {
    OVERRIDE_FILE="$terraform_module/backend_override.tf"

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

    function tf_init_http_migrate () {
        run terraform -chdir="$terraform_module" init \
                      -migrate-state \
                      -force-copy \
                      -upgrade \
                      -backend-config="address=$backend_address" \
                      -backend-config="lock_address=$backend_address/lock" \
                      -backend-config="unlock_address=$backend_address/lock" \
                      -backend-config="lock_method=POST" \
                      -backend-config="unlock_method=DELETE" \
                      -backend-config="retry_wait_min=5"
    }

    function tf_init_local_migrate () {
        run terraform -chdir="$terraform_module" init \
                      -migrate-state \
                      -force-copy \
                      -upgrade
        return $?
    }

    all_gitlab_vars=("gitlab_base_url" "gitlab_project_id" "gitlab_state_name")

    function all_gitlab_vars_are_set() {
        for var in "${all_gitlab_vars[@]}"; do
            [[ -z "${!var}" || "${!var}" == "null" ]] && return 1
        done
        return 0
    }

    function all_gitlab_vars_are_unset() {
        for var in "${all_gitlab_vars[@]}"; do
            [[ -n "${!var}" && "${!var}" != "null" ]] && return 1
        done
        return 0
    }

    function tf_state_present_on_gitlab () {
        if [ -z "${TF_HTTP_PASSWORD:-}" ]; then
            errorf "We want to check if there is a Gitlab state present,"
            errorf "but no TF_HTTP_PASSWORD provided!"
            errorf "If you're using local backend"
            errorf "make sure that all the following GitLab variables are unset:"
            for var in "${all_gitlab_vars[@]}"; do
                errorf "- $var"
            done
            exit 2
        fi
        GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" "$backend_address")
        check_return_code "$GITLAB_RESPONSE"
    }

    load_gitlab_vars

    if all_gitlab_vars_are_set; then
        if tf_state_present_on_gitlab && [ -f "$terraform_state_dir/terraform.tfstate" ]; then
            errorf "Several Terraform statefiles were found: locally and on GitLab."
            exit 1
        fi
    fi

    # gitlab_backend=true
    if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
        if ! all_gitlab_vars_are_set; then
            errorf "'gitlab_backend=true' but GitLab variables are not (completely) provided."
            exit 2
        fi

        # Here we create an override_file which overrides the `local` terraform backend to http(gitlab) backend
        if [ ! -f "$OVERRIDE_FILE" ]; then
        cat > "$OVERRIDE_FILE" <<-EOF
terraform {
	backend "http" {}
}
EOF
        fi

        if tf_state_present_on_gitlab; then
            tf_init_http
        else
            if  [ -f "$terraform_state_dir/terraform.tfstate" ]; then
                tf_init_http_migrate
                # Delete terraform statefiles locally if they exist (-f)
                rm -f "$terraform_state_dir/terraform.tfstate" "$terraform_state_dir/terraform.tfstate.backup"
            else
                tf_init_http    # first init
            fi
        fi

    # gitlab_backend=false
    else
        if ! all_gitlab_vars_are_set && ! all_gitlab_vars_are_unset; then
            errorf "'gitlab_backend=false' but some GitLab variables are provided."
            errorf "(1) If you want to migrate the Terraform backend method from 'http' to 'local',"
            errorf "you should provide all the GitLab variables"
            errorf "(2) If you want to init a cluster with local backend,"
            errorf "make sure that all the following GitLab variables are unset:"
            for var in "${all_gitlab_vars[@]}"; do
                errorf "- $var"
            done
            exit 2
        fi

        if all_gitlab_vars_are_set; then
            if tf_state_present_on_gitlab; then
                rm -f "$OVERRIDE_FILE"
                notef "Terraform statefile on GitLab found. Migration from http to local."
                if tf_init_local_migrate; then
                    # delete tf_statefile from GitLab
                    GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" --request DELETE "$backend_address")
                    check_return_code "$GITLAB_RESPONSE"
                else
                    warningf "Terraform init was not successful. The Terraform state on GitLab was not deleted."
                fi
            else
                errorf "'gitlab_backend=false', all GitLab variables are provided,"
                errorf "but the Terrafrom state file could not be found on GitLab in order to migrate from 'http' to 'local'."
                errorf "(1) If you want to migrate, make sure the Terraform state file exists on GitLab."
                errorf "(2) If you want to init a cluster with local backend,"
                errorf "make sure that all the following GitLab variables are unset:"
                for var in "${all_gitlab_vars[@]}"; do
                    errorf "- $var"
                done
                exit 2
            fi
        else
            rm -f "$OVERRIDE_FILE"
            tf_init_local
        fi
    fi
}
