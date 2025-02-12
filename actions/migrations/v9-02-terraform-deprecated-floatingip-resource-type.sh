#!/usr/bin/env bash

# Remove deprecated `openstack_compute_floatingip_associate_v2` Terraform
# resources from the local Terraform state so they are properly replaced
# with `openstack_networking_floatingip_v2` ones. (WORKAROUND)
#
# Unfortunately, the Terraform Openstack provider is not smart enough to take
# into account the non-object nature of floating ip associations in Openstack.
# Terraform first creates the new resources, then destroys the deprecated ones
# which results the floating ips actually being disassociated in Openstack.
# Terraform cannot be made to perform both actions in reverse order.
# Thus, first the deprecated resources have to be removed from the Terraform
# state.

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

load_conf_vars

# migration of deprecated Terraform floating ip resources (if needed)

if [ "${tf_usage:-true}" == 'true' ]; then

  tf_init

  notef "Removing deprecated Terraform floatingip resources from state..."

  tf_statefile_temp="$terraform_state_dir/terraform.tfstate.yk8s-v9-migrated"
  terraform -chdir="$terraform_module" state pull > "$tf_statefile_temp"

  if ( \
    terraform -chdir="$terraform_module" state list -state="$tf_statefile_temp" \
    | grep --quiet '^openstack_compute_floatingip_associate_v2\.gateway' \
  ); then

    run terraform -chdir="$terraform_module" state rm -state="$tf_statefile_temp" \
      openstack_compute_floatingip_associate_v2.gateway

    run terraform -chdir="$terraform_module" state push "$tf_statefile_temp"

    notef "Deprecated Terraform floating ip resources removed from state."
    notef "Running apply-terraform to create their replacements..."

    run "$actions_dir/apply-terraform.sh"

  else
      notef "Nothing to do."
  fi

  rm "$tf_statefile_temp"

  run git add "$terraform_state_dir"
else
  notef "Skipped Terraform related migration because it is disabled."
fi
