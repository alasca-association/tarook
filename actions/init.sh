#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

submodule_base="submodules"

submodule_managed_k8s_name="managed-k8s"
submodule_managed_k8s_url="${MANAGED_K8S_GIT:-https://gitlab.com/yaook/k8s.git}"

submodule_wg_user_name="wg_user"
submodule_wg_user_git="${MANAGED_K8S_WG_USER_GIT:-git@gitlab.cloudandheat.com:lcm/wg_user}"

submodule_passwordstore_users_repo_name="passwordstore_users"
submodule_passwordstore_users_git="${MANAGED_K8S_PASSWORDSTORE_USER_GIT:-git@gitlab.cloudandheat.com:lcm/mk8s-passwordstore-users}"

submodule_ch_role_users_repo_name="ch-role-users"
submodule_ch_role_user_git="${MANAGED_CH_ROLE_USER_GIT:-git@gitlab.cloudandheat.com:operations/ansible-roles/ch-role-users.git}"

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
	if [ ! -d "$submodule_managed_k8s_name" ]; then
		run git submodule add "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
	else
		pushd "$cluster_repository/$submodule_managed_k8s_name" > /dev/null
		run git remote set-url origin "$submodule_managed_k8s_url"
		popd > /dev/null
	fi
else
	echo ''
	notef "Skipping $submodule_managed_k8s_name submodule.."
	echo ''
fi

# Create submodule directory
mkdir -p "$submodule_base"

# Add the Cloud&Heat wireguard peers repository as submodule
if [ "${WG_COMPANY_USERS:-true}" == "true" ]; then
    if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
        if [ -d "$submodule_wg_user_name" ]; then
            run git mv "$submodule_wg_user_name" "$submodule_base/$submodule_wg_user_name"
        else
            if [ ! -d "$submodule_base/$submodule_wg_user_name" ]; then
                run git submodule add "$submodule_wg_user_git" "$submodule_base/$submodule_wg_user_name"
            else
                pushd "$cluster_repository/$submodule_base/$submodule_wg_user_name" > /dev/null
                run git remote set-url origin "$submodule_wg_user_git"
                popd > /dev/null
            fi
        fi
    else
        run git clone "$submodule_wg_user_git" "$submodule_base/$submodule_wg_user_name"
    fi
fi

# Add the Cloud&Heat mk8s pass users repository as submodule
if [ "${PASS_COMPANY_USERS:-true}" == "true" ]; then
    if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
        if [ -d "$submodule_passwordstore_users_repo_name" ]; then
            run git mv "$submodule_passwordstore_users_repo_name" "$submodule_base/$submodule_passwordstore_users_repo_name"
        else
            if [ ! -d "$submodule_base/$submodule_passwordstore_users_repo_name" ]; then
                run git submodule add "$submodule_passwordstore_users_git" "$submodule_base/$submodule_passwordstore_users_repo_name"
            else
                pushd "$cluster_repository/$submodule_base/$submodule_passwordstore_users_repo_name" > /dev/null
                run git remote set-url origin "$submodule_passwordstore_users_git"
                popd > /dev/null
            fi
        fi
    else
        run git clone "$submodule_passwordstore_users_git" "$submodule_base/$submodule_passwordstore_users_repo_name"
    fi
fi

# Add the Cloud&Heat cah-role-users repository as submodule
if [ "${SSH_COMPANY_USERS:-true}" == "true" ]; then
  if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
        if [ -d "$submodule_ch_role_users_repo_name" ]; then
            run git mv "$submodule_ch_role_users_repo_name" "$submodule_base/$submodule_ch_role_users_repo_name"
        else
            if [ ! -d "$submodule_base/$submodule_ch_role_users_repo_name" ]; then
                run git submodule add "$submodule_ch_role_user_git" "$submodule_base/$submodule_ch_role_users_repo_name"
            else
                pushd "$cluster_repository/$submodule_base/$submodule_ch_role_users_repo_name" > /dev/null
                run git remote set-url origin "$submodule_ch_role_user_git"
                popd > /dev/null
            fi
        fi
  else
    run git clone "$submodule_ch_role_user_git" "$submodule_base/$submodule_ch_role_users_repo_name"
  fi
fi

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    run git submodule update --init --recursive
fi

new_actions_dir="$submodule_managed_k8s_name/actions"
if [ "$(realpath "$new_actions_dir")" != "$(realpath "$actions_dir")" ]; then
    if [ -x "$new_actions_dir/init.sh" ]; then
        # execute init from the cloned repository; it should not change anything
        # but it’ll provide a consistent state
        hintf 're-executing init.sh from local submodule'
        exec "$new_actions_dir/init.sh"
    else
        # huh? no executable init.sh in the cloned repository. weird, but let’s
        # continue.
        warningf "no executable init.sh action in the $submodule_managed_k8s_name submodule"
        hintf "this means that the cloned $submodule_managed_k8s_name submodule is unexpectedly old"
        hintf 'we will try continue to operate using the init.sh you called initially\n\n'

        # reload all variables with the new base
        actions_dir="$new_actions_dir"
        # shellcheck source=actions/lib.sh
        . "$actions_dir/lib.sh"
    fi
fi

# Create Vault development container
if [ "${USE_VAULT_IN_DOCKER:-false}" == "true" ]; then
  "$actions_dir/vault.sh"
fi

mkdir -p config
cp "$code_repository/templates/template.gitignore" .gitignore
cp --no-clobber "$code_repository/templates/config.template.toml" config/config.toml
if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
	run git add .gitignore config/config.toml
fi

if [ "${K8S_CUSTOM_STAGE_USAGE:-false}" == 'true' ]; then
    mkdir -p "$ansible_inventory_base/99_custom"
    mkdir -p "$ansible_k8s_custom_playbook"

    ln -sf ../03_k8s_base/hosts inventory/99_custom/hosts

    if [ ! -d "$ansible_k8s_custom_playbook/inventory" ]; then
        cp -r "$code_repository/k8s-managed-services/inventory" "$ansible_k8s_custom_playbook/inventory"
    fi

    mkdir -p "$ansible_k8s_custom_playbook/roles"

    if [ ! -f "$ansible_k8s_custom_playbook/main.yaml" ]; then
        echo "# Add your roles and tasks here:" > "$ansible_k8s_custom_playbook/main.yaml"
    fi

    mkdir -p "$ansible_k8s_custom_playbook/vars"
    ln -sf "../../managed-k8s/k8s-base/vars/" "$ansible_k8s_custom_playbook/vars/k8s-base-vars"
    ln -sf "../../managed-k8s/k8s-service-layer/vars/" "$ansible_k8s_custom_playbook/vars/ksl-vars"
fi

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
	notef 'cluster repository initialised successfully!'
	notef 'You should now update config/config.toml as needed and '
	notef 'then run git commit -v to check and commit your changes'
else
	notef 'Preparations for standalone deployment completed'
	notef 'You should now update config/config.toml as needed and '
	notef 'inventory/02_trampoline/hosts with your server IPs'
fi

notef 'Make sure to set your user specific variables in one'
notef 'of the supported ways, see '"$submodule_managed_k8s_name"'/templates/yaook-k8s-env.template.sh'
