#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

helpf() {
  action_name=${0##*/}
  printf "%s - Action Script for k8s-core\n\n" "$action_name"
  printf "Usage: %s [list|help] <playbook>\n\n" "$action_name"
  printf "Commands:\n"
  printf "list          List available playbooks\n"
  printf "help          Print this help message\n"
  printf "<playbook>    Trigger specific playbook\n"
  printf "              If not supplied, 'install-all.yaml' is triggered\n"
}

optionsf() {
  printf "Available playbooks:\n\n"
  printf '%s\n' "${playbooks[@]}"
}

execute_playbook() {
  local playbook="$1"
  notef "Executing playbook $playbook\n"

  load_conf_vars
  check_venv
  check_conf_sanity
  require_vault_token
  install_prerequisites

  # Ensure that the latest config is deployed to the inventory
  python3 "$actions_dir/update_inventory.py"
  # Bring the wireguard interface up if configured so
  "$actions_dir/wg-up.sh"

  set_kubeconfig

  pushd "$ansible_k8s_core_dir"
  # Include k8s-core roles
  ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles" \
    ansible_playbook -i "$ansible_inventory_host_file" \
    -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
    "$playbook"
  popd
}

arg_num=1
if [ "$#" -gt "$arg_num" ]; then
    errorf "ERROR: Expecting at most $arg_num argument(s), but $# were given" >&2
    helpf
    exit 1
fi

if [ "$#" == "0" ]; then
  # Trigger whole LCM by default
  execute_playbook "install-all.yaml"
  exit 0
fi

command="$1"

if [ "$command" == "help" ]; then
  helpf
  exit 0
fi

readarray -d '\n' playbooks <  <(find "$ansible_k8s_core_dir" \
                                  \( \
                                  -name 'install-*.yaml' \
                                  -or -name 'bootstrap.yaml' \
                                  \) -type f -printf "%f\n" | sort)

if [ "$command" == "list" ]; then
  optionsf
  exit 0
fi

# shellcheck disable=SC2068
for i in ${playbooks[@]}; do
  if [[ "$i" == "$command" ]]; then
    execute_playbook "$command"
    exit 0
  fi
done

errorf "$command is not a valid playbook" >&2
helpf
exit 2
