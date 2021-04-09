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

if [ ! -d "$submodule_managed_k8s_name" ]; then
    run git submodule add "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
else
    run git submodule set-url "$submodule_managed_k8s_name" "$submodule_managed_k8s_url"
fi

if [ ! -d "$submodule_wg_user_name" ]; then
    run git submodule add "$submodule_wg_user_git" "$submodule_wg_user_name"
else
    run git submodule set-url "$submodule_wg_user_name" "$submodule_wg_user_git"
fi

if [ ! -d "$submodule_passwordstore_users_name" ]; then
    run git submodule add "$submodule_passwordstore_users_git" "$submodule_passwordstore_users_name"
else
    run git submodule set-url "$submodule_passwordstore_users_name" "$submodule_passwordstore_users_git"
fi


run git submodule update --init --recursive

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
run git add .gitignore config/config.toml

notef 'cluster repository initialised successfully!'
notef 'You should now update config/config.toml as needed and '
notef 'then run git commit -v to check and commit your changes'
