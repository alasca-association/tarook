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

  notef "Removing deprecated Terraform floatingip resources from state..."

  load_gitlab_vars

  gitlab_backend_used=null
  # Determine whether Gitlab is used as backend
  if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
    # If Gitlab is used as backend,
    # do some some sanity checks
    if all_gitlab_vars_are_set; then
      if tf_state_present_on_gitlab && [ -f "$terraform_state_dir/terraform.tfstate" ]; then
        errorf "Several Terraform statefiles were found: locally and on GitLab."
        errorf "You have to remove the faulty one."
        exit 1
      elif tf_state_present_on_gitlab; then
        notef "Terraform backend: Gitlab is used as Terraform backend."
        gitlab_backend_used=true
      else
        errorf "Gitlab is configured as Terraform backend, but no Terraform state was found."
        errorf "Something is seriously odd. You must manually fix it."
        errorf "You can migrate from local state to Gitlab backend only before starting the migration to the next release."
        exit 2
      fi
    fi
  else
    notef "Terraform backend: A local state file is used as Terraform backend."
    gitlab_backend_used=false
  fi

  if [ "${gitlab_backend_used}" == 'true' ]; then
    # If Gitlab is used as backend, we have to temporarily migrate to local state.
    # It will be migrated back to Gitlab when triggering apply-terraform.sh below
    notef 'Pulling latest Terraform state from Gitlab for disaster recovery purposes.'
    # don't use the "run" function here as it would print the token
    curl -s -o "$terraform_state_dir/disaster-recovery.tfstate.bak" \
        --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address"
    # Temporarily remove the override file such that Terraform switches to local state
    rm -f "$TERRAFORM_OVERRIDE_FILE"
    # Trigger the migration from http to local...
    if TF_DATA_DIR="$terraform_state_dir/.terraform" tf_init_local_migrate; then
      # ... and if this succeeds, we have to delete that state from Gitlab as otherwise
      # apply-terraform will complain that both a local and a remote state exist
      notef 'Temporarily removing Terraform state from Gitlab'
      GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" --request DELETE "$backend_address")
      check_return_code "$GITLAB_RESPONSE"
    fi
  fi

  # Check if we have to tinker with the Terraform state
  if ( \
    terraform state list -state="$terraform_state_dir/terraform.tfstate" \
    | grep --quiet '^openstack_compute_floatingip_associate_v2\.gateway' \
  ); then
    notef "Deprecated Terraform floating ip resources detected."
    notef "Removing deprecated Terraform floating ip resources from state now..."

    # Tinker with the Terraform state
    run terraform state rm -state="$terraform_state_dir/terraform.tfstate" \
      openstack_compute_floatingip_associate_v2.gateway

    notef "Deprecated Terraform floating ip resources removed from state."
    notef "Running apply-terraform to create their replacements..."

    if [ "${gitlab_backend_used}" == 'true' ]; then
      notef "This will also migrate the currently local Terraform state back to Gitlab."
    fi

    run "$actions_dir/apply-terraform.sh"
    run git add "$terraform_state_dir"

  elif [ "${gitlab_backend_used}" == 'true' ]; then
    # even if we did not tinker with the Terraform state,
    # we still must migrate it back from local to Gitlab
    notef "Triggering Terraform to migrate the currently local Terraform state back to Gitlab."
    IGNORE_MIGRATION_LOCK=true run "$actions_dir/apply-terraform.sh"
    run git add "$terraform_state_dir"
  else
      notef "Nothing to do."
  fi

else
  notef "Skipped Terraform related migration because it is disabled."
fi
