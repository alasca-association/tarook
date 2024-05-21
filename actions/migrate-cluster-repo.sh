#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

# Move etc directory
if [ ! -d "$etc_directory" ]; then
  if [ -d "inventory/.etc" ]; then
    run mv "inventory/.etc" "$etc_directory"
  else
    notef 'Neither new nor old etc-directory are present.'
    notef 'Something is odd. Please take manual actions.'
    exit 1
  fi
fi
if [[ "$TF_USAGE" == "false" ]] && [[ -e inventory/02_trampoline/hosts ]]; then
  run mv "$(realpath inventory/02_trampoline/hosts)" hosts.bak
fi
if [ -d "inventory" ]; then
  run rm -r "inventory"
fi

# Apply terraform (for variable output)
if [[ "$TF_USAGE" == "true" ]]; then
  run "./$actions_dir/apply-terraform.sh"
elif [[ -e hosts.bak ]]; then
  run mkdir -p inventory/yaook-k8s
  run mv hosts.bak inventory/yaook-k8s/hosts
fi

# Run inventory updater
run "./$actions_dir/update_inventory.py"

# Migrate custom stage
if [ -z "${K8S_CUSTOM_STAGE_USAGE:-}" ]; then
  errorf "Please set K8S_CUSTOM_STAGE_USAGE as environment variable."
  errorf "Check templates/envrc.template.sh for help"
fi
if [ "${K8S_CUSTOM_STAGE_USAGE}" == 'true' ]; then
  if [ -L "k8s-custom/vars/k8s-base-vars" ]; then
    run rm "k8s-custom/vars/k8s-base-vars"
  fi
  if [ -L "k8s-custom/vars/ksl-vars" ]; then
    run rm "k8s-custom/vars/ksl-vars"
  fi
  if [ ! -L "$ansible_k8s_custom_playbook/vars/k8s-core-vars" ]; then
    run ln -sf "../../$submodule_managed_k8s_name/k8s-core/ansible/vars/" "$ansible_k8s_custom_playbook/vars/k8s-core-vars"
  fi
  if [ ! -L "$ansible_k8s_custom_playbook/vars/k8s-supplements-vars" ]; then
    run ln -sf "../../$submodule_managed_k8s_name/k8s-supplements/ansible/vars/" "$ansible_k8s_custom_playbook/vars/k8s-supplements-vars"
  fi
  if [ -f "k8s-custom/inventory/default.yaml" ]; then
    run rm "k8s-custom/inventory/default.yaml"
  fi
  if [ -f "k8s-custom/inventory/README.md" ]; then
    run rm "k8s-custom/inventory/README.md"
  fi
  if [ -d "k8s-custom/inventory" ]; then
    run rmdir "k8s-custom/inventory"
  fi
fi

# Copy gitignore
run cp "$submodule_managed_k8s_name/templates/template.gitignore" ".gitignore"

# Fix KUBECONFIG
if [[ -n "${KUBECONFIG}" ]]; then
  run sed -i 's#inventory/.etc/admin.conf#etc/admin.conf#' .envrc
fi

# Fix .gitattribues
if [ -f ".gitattributes" ]; then
  run sed -i 's#inventory/.etc#etc#' .gitattributes
fi

notef 'Cluster repository successfully migrated!'
notef 'You should now verify everything works as expected'
notef 'and then commit the changes!\n\n'
