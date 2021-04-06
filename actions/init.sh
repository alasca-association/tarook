#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# this is workaround as it's required for lib.sh
# we don't need these variables for that script
export wg_conf_name=
export wg_user=

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

submodule_managed_k8s_name="managed-k8s"
submodule_managed_k8s_url="${MANAGED_K8S_GIT:-git@gitlab.cloudandheat.com:lcm/managed-k8s}"
submodule_wg_user_name="wg_user"
submodule_wg_user_git="${MANAGED_K8S_WG_USER_GIT:-git@gitlab.cloudandheat.com:lcm/wg_user}"
submodule_passwordstore_users_name="passwordstore-users"
submodule_passwordstore_users_git="${MANAGED_K8S_PASSWORDSTORE_USER_GIT:-git@gitlab.cloudandheat.com:lcm/mk8s-passwordstore-users}"
submodule_ch_role_user_git="${MANAGED_CH_ROLE_USER_GIT:-git@gitlab.cloudandheat.com:operations/ansible-roles/ch-role-users.git}"

if [ ! "$actions_dir" == "./managed-k8s/actions" ]; then
	if [ ! -d "$submodule_managed_k8s_name" ]; then
		run git submodule add "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
	else
		pushd "$cluster_repository"/managed-k8s > /dev/null
		run git remote set-url origin "$submodule_managed_k8s_url"
		popd > /dev/null
	fi
else
	echo ""
	notef 'Skipping managed-k8s submodule..'
	echo ""
fi

test_repo_access "$submodule_wg_user_git"
if [ ! "$EXITCODE" -eq 128 ]; then
	if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
		if [ ! -d "$submodule_wg_user_name" ]; then
			run git submodule add "$submodule_wg_user_git" "$submodule_wg_user_name"
		else
			pushd "$cluster_repository"/wg_user > /dev/null
			run git remote set-url origin "$submodule_wg_user_git"
			popd > /dev/null
		fi
	else
		run git clone "$submodule_wg_user_git"
	fi
else
	notef 'Access to C&Hs WireGuard user repo is missing. Skipping..'
	echo ""
fi

test_repo_access "$submodule_ch_role_user_git"
if [ "$EXITCODE" -eq 128 ]; then
	warningf 'Access to C&Hs user repo is missing. Removing submodule'
	warningf '-------------------------------------------------------'
	warningf '🚨  DO NOT PUSH YOUR CLUSTER REPO BECAUSE OF THAT!  🚨'
	echo ""
	pushd "$cluster_repository/managed-k8s" > /dev/null
	if [ -d "managed-k8s/ansible/roles/ch-role-users/" ]; then
		run git rm ansible/roles/ch-role-users
	fi
	mkdir -p ansible/roles/ch-role-users
	popd > /dev/null
fi

test_repo_access "$submodule_passwordstore_users_git"
if [ ! "$EXITCODE" -eq 128 ]; then
	if [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
		if [ ! -d "$submodule_passwordstore_users_name" ]; then
			run git submodule add "$submodule_passwordstore_users_git" "$submodule_passwordstore_users_name"
		else
			run git remote set-url origin "$submodule_passwordstore_users_git"
		fi
	else
		run git clone "$submodule_passwordstore_users_git"
	fi
else
	notef 'Access to C&Hs Password Store repo is missing. Skipping..'
	echo ""
fi

if [ ! "$actions_dir" == "./managed-k8s/actions" ]; then
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
        warningf 'no executable init.sh action in the managed-k8s submodule'
        hintf 'this means that the cloned managed-k8s submodule is unexpectedly old'
        hintf 'we will try continue to operate using the init.sh you called initially\n\n'

        # reload all variables with the new base
        actions_dir="$new_actions_dir"
        # shellcheck source=actions/lib.sh
        . "$actions_dir/lib.sh"
    fi
fi

mkdir -p config
cp "$code_repository/jenkins/template.gitignore" .gitignore
cp --no-clobber "$code_repository/jenkins/config.template.toml" config/config.toml
if [ ! $actions_dir == "./managed-k8s/actions" ]; then
	run git add .gitignore config/config.toml
fi

if [ ! -d "$ansible_inventory_base" ]; then
	mkdir -p inventory
	mkdir -p inventory/02_trampoline
	mkdir -p inventory/03_final
	cp --no-clobber "$code_repository/jenkins/hosts.template" inventory/02_trampoline/hosts
fi

if [ ! $actions_dir == "./managed-k8s/actions" ]; then
	notef 'cluster repository initialised successfully!'
	notef 'You should now update config/config.toml as needed and '
	notef 'then run git commit -v to check and commit your changes'
else
	notef 'Preparations for standalone deployment completed'
	notef 'You should now update config/config.toml as needed and '
	notef 'inventory/02_trampoline/hosts with your server IPs'
fi