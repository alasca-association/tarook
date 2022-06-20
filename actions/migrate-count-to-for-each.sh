#!/bin/bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

var_file="$terraform_state_dir/config.tfvars.json"
terraform_console_remove_quotes () {
  echo "$1" | terraform -chdir="$terraform_module" console -var-file="$var_file" | sed -e 's/^"//' -e 's/"$//'
}

cd "$terraform_state_dir"
export TF_DATA_DIR="$terraform_state_dir/.terraform"
run terraform -chdir="$terraform_module" init

# Read the name of the cluster and instances.
cluster_name=$(terraform_console_remove_quotes "var.cluster_name")
# Use here-string instead of pipe to read arrays because variables are used also later in the script
read -r -a worker_names <<< "$(terraform_console_remove_quotes 'join(" ", var.worker_names)')"
read -r -a master_names <<< "$(terraform_console_remove_quotes 'join(" ", var.master_names)')"
read -r -a azs <<< "$(terraform_console_remove_quotes 'join(" ", var.azs)')"

# Go through each resource in terraform state and generate 'moved' blocks.
# E.g. for renaming openstack_compute_instance_v2.worker[0] to openstack_compute_instance_v2.worker["managed-k8s-worker-0"]
# find resource worker[0], generate new index key based on cluster and worker name and write 'moved' configuration block to the file.
moved_block="moved {\n  from = %s\n  to   = %s\n}\n\n"
terraform -chdir="$terraform_module" state list | while read -r resource ; do
  # worker or worker-volume
  read -r type name worker_idx <<< "$(echo "$resource" | sed -n 's/^\(.*\)\.\(worker\|worker-volume\)\[\([0-9]*\)\]$/\1 \2 \3/p')"
  if [ -n "$worker_idx" ]
  then
    worker_name="$cluster_name-worker-${worker_names[$worker_idx]:-$worker_idx}"
    # shellcheck disable=SC2059
    printf "$moved_block" "$resource" "$type.${name}[\"$worker_name\"]"
    continue
  fi

  # master or master-volume
  read -r type name master_idx <<< "$(echo "$resource" | sed -n 's/^\(.*\)\.\(master\|master-volume\)\[\([0-9]*\)\]$/\1 \2 \3/p')"
  if [ -n "$master_idx" ]
  then
    master_name="$cluster_name-master-${master_names[$master_idx]:-$master_idx}"
    # shellcheck disable=SC2059
    printf "$moved_block" "$resource" "$type.${name}[\"$master_name\"]"
    continue
  fi

  # gateway or gateway-volume
  read -r type name gateway_idx <<< "$(echo "$resource" | sed -n 's/^\(.*\)\.\(gateway\|gateway-volume\)\[\([0-9]*\)\]$/\1 \2 \3/p')"
  if [ -n "$gateway_idx" ]
  then
    gateway_name="$cluster_name-gw-${azs[$gateway_idx],,}"
    # shellcheck disable=SC2059
    printf "$moved_block" "$resource" "$type.${name}[\"$gateway_name\"]"
    continue
  fi
done > "$terraform_module/moved-instances.tf"

run terraform -chdir="$terraform_module" plan --var-file="$var_file"

notef 'The first step(generate migration configuration) of migration of count to for_each completed'
notef "You can find generated 'moved' configuration blocks in the $terraform_module/moved-instances.tf"
notef 'If you want to migrate, run the apply-terraform.sh script after reviewing that file and a terraform plan located above'
