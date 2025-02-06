#!/usr/bin/env bash

# Remove deprecated `openstack_compute_floatingip_associate_v2` Terraform
# resources from the local Terraform state so they are properly replaced
# with `openstack_networking_floatingip_v2` ones. (WORKAROUND)
#
# Unfortunately, the Terraform Openstack provider is not smart enough to take
# into account the non-object nature of floating ip associations in Openstack.
# Terraform first creates the new resources, then destroys the deprecated ones
# which results the floating ips actuelly being disassociated in Openstack.
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

  notef "Removing deprecated Terraform floatingip resources from state..."

  pushd "$cluster_repository" >/dev/null || exit 1

  tf_init_local

  if ( \
    terraform state list -state="$terraform_state_dir/terraform.tfstate" \
    | grep --quiet '^openstack_compute_floatingip_associate_v2\.gateway' \
  ); then

    run terraform state rm -state="$terraform_state_dir/terraform.tfstate" \
      openstack_compute_floatingip_associate_v2.gateway

    notef "\nDeprecated Terraform floating ip resources removed from state."
    notef "Running apply-terraform to create their replacements..."

    run "$actions_dir/apply-terraform.sh"

  else
      notef "Nothing to do."
  fi

  popd >/dev/null || exit 1

else
  notef "Skipped Terraform related migration because it is disabled."
fi
