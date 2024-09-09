#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

submodule_base="submodules"

submodule_managed_k8s_url="${MANAGED_K8S_GIT:-https://gitlab.com/yaook/k8s.git}"

submodule_wg_user_name="wg_user"
submodule_wg_user_git="${MANAGED_K8S_WG_USER_GIT:-git@gitlab.cloudandheat.com:lcm/wg_user}"

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    if [ ! -d "$submodule_managed_k8s_name" ]; then
        if [ "${MANAGED_K8S_LATEST_RELEASE:-true}"  == "true" ]; then
            # Checkout latest release
            version_major_minor=$(grep -Po '^[0-9]+\.[0-9]+' "$actions_dir/../version")

            echo ''
            notef "Adding $submodule_managed_k8s_name submodule on release v$version_major_minor..."

            run git submodule add -b "release/v$version_major_minor" "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
        elif [ -n "${MANAGED_K8S_GIT_BRANCH:-}" ]; then
            # Checkout specified branch

            echo ''
            notef "Adding $submodule_managed_k8s_name submodule on branch $MANAGED_K8S_GIT_BRANCH..."

            run git submodule add -b "$MANAGED_K8S_GIT_BRANCH" "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
        else
            run git submodule add "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
        fi
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

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    run git submodule update --init --recursive
fi

new_actions_dir="$submodule_managed_k8s_name/actions"
if [ "$(realpath "$new_actions_dir")" != "$(realpath "$actions_dir")" ]; then
    if [ -x "$new_actions_dir/init-cluster-repo.sh" ]; then
        # execute init from the cloned repository; it should not change anything
        # but it’ll provide a consistent state
        hintf 're-executing init-cluster-repo.sh from local submodule'
        exec "$new_actions_dir/init-cluster-repo.sh"
    else
        warningf "no executable init-cluster-repo.sh action in the $submodule_managed_k8s_name submodule"
        hintf "this means that the cloned $submodule_managed_k8s_name submodule is unexpectedly old"
        hintf 'we will fail now.'
        exit 1
    fi
fi

# Create Vault development container
if [ "${USE_VAULT_IN_DOCKER:-false}" == "true" ]; then
  "$actions_dir/vault.sh"
fi

mkdir -p config
cp "$code_repository/templates/template.gitignore" .gitignore
if [ -f config/config.toml ]; then
    warningf "config/config.toml already exists, refusing to overwrite"
else
    cp --no-clobber "$code_repository/templates/config.template.toml" config/config.toml
fi
if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
	run git add .gitignore config/config.toml
fi

# custom stage
mkdir -p "$ansible_k8s_custom_inventory"
mkdir -p "$ansible_k8s_custom_playbook_dir"
mkdir -p "$ansible_k8s_custom_playbook_dir/roles"

if [ ! -f "$ansible_k8s_custom_playbook" ]; then
    playbook_text="# Add your roles and tasks here:\n"
    playbook_text+="- hosts: orchestrator\n"
    playbook_text+="  gather_facts: false\n"
    playbook_text+="  tasks:\n"
    playbook_text+="  - ansible.builtin.meta: noop"
    echo -e "$playbook_text" > "$ansible_k8s_custom_playbook"
fi

mkdir -p "$ansible_k8s_custom_playbook_dir/vars"
ln -sf "../../managed-k8s/k8s-core/ansible/vars/" "$ansible_k8s_custom_playbook_dir/vars/k8s-core-vars"
ln -sf "../../managed-k8s/k8s-supplements/ansible/vars/" "$ansible_k8s_custom_playbook_dir/vars/k8s-supplements-vars"

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
