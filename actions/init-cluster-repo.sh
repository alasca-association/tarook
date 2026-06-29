#!/usr/bin/env bash
set -euo pipefail
submodule_managed_k8s_url="${MANAGED_K8S_GIT:-https://gitlab.com/alasca.cloud/tarook/tarook.git}"

###
# Before doing anything else, we check whether a branch was passed via -b
# If so, we run the init script from the specified branch instead,
# passing all other arguments unaltered
# NOTE: There should be no logic before this, in order to ensure compatibility with all branches that provide #init
for arg in "$@"; do
    if [[ "$arg" == -b ]]; then
        # Branch was passed

        branch=""
        other_args=()

        while [[ $# -gt 0 ]]; do
            case "$1" in
                -b)
                    branch="$2"
                    shift 2
                    ;;
                *)
                    other_args+=("$1")
                    shift
                    ;;
            esac
        done

        url="git+${submodule_managed_k8s_url}?ref=${branch}"
        >&2 echo "Executing init script from ${url}"
        export managed_k8s_latest_release=false
        export managed_k8s_git_branch="$branch"
        exec nix run "${url}#init" -- "${other_args[@]}"
    fi
done
#
###

actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

usage() {
    >&2 echo "Usage: nix run <flake-url>#init [-b BRANCH] TEMPLATE"
    >&2 echo ""
    >&2 echo "Arguments:"
    >&2 echo "    -b BRANCH   Tarook branch to checkout in git submodule"
    >&2 echo "    TEMPLATE    Flavor of initial configuration to setup"
    >&2 echo "                One of: $(cluster_repo_template_list)"
}

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    errorf "Expecting $arg_num argument(s), but $# were given"
    echo >&2
    usage
    exit 2
fi

check_nix_version

template="${1}"

if [[ "$template" == */* || ! -e "${cluster_repo_template_dir:?}/${template:?}" ]]; then
    errorf "Unsupported template."
    hintf "Currently supported templates: $(cluster_repo_template_list)"
    exit 1
fi

submodule_base="submodules"


if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    if [ ! -d "$submodule_managed_k8s_name" ]; then
        if [ "${managed_k8s_latest_release:-true}"  == "true" ]; then
            # Checkout latest release
            echo ''
            notef "Adding $submodule_managed_k8s_name submodule on release v$version_major_minor..."

            run git submodule add -b "release/v$version_major_minor" "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
        elif [ -n "${managed_k8s_git_branch:-}" ]; then
            # Checkout specified branch

            echo ''
            notef "Adding $submodule_managed_k8s_name submodule on branch $managed_k8s_git_branch..."

            run git submodule add -b "$managed_k8s_git_branch" "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
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

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    run git submodule update --init --recursive
fi

# Copy template directory and dereference any symlinks pointing outside of it
#  (namely symlinks from other templates into ../minimal/)
rsync --verbose --chmod=F644,D755 --recursive --links --copy-unsafe-links --ignore-existing "${cluster_repo_template_dir:?}/${template}"/ .
if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    # TODO foreach file: only add if not already tracked or in index
	run git add flake.nix .gitignore config .envrc
fi

nix flake lock

run git add flake.lock
# custom stage
mkdir -p "$ansible_k8s_custom_inventory"
mkdir -p "$ansible_k8s_custom_playbook_dir"
mkdir -p "$ansible_k8s_custom_playbook_dir/roles"

if [ ! -f "$ansible_k8s_custom_playbook" ]; then
    playbook_text="# Add your roles and tasks here:\n"
    playbook_text+="- hosts: orchestrator\n"
    playbook_text+="  gather_facts: false\n"
    playbook_text+="  tasks:\n"
    playbook_text+="  - meta: noop"
    echo -e "$playbook_text" > "$ansible_k8s_custom_playbook"
fi

mkdir -p "$ansible_k8s_custom_playbook_dir/vars"
ln -sf "../../managed-k8s/k8s-core/ansible/vars/" "$ansible_k8s_custom_playbook_dir/vars/k8s-core-vars"
ln -sf "../../managed-k8s/k8s-supplements/ansible/vars/" "$ansible_k8s_custom_playbook_dir/vars/k8s-supplements-vars"

if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
	notef 'cluster repository initialised successfully!'
	notef 'You should now update config/default.nix as needed and '
	notef 'then run git commit -v to check and commit your changes'
else
	notef 'Preparations for standalone deployment completed'
	notef 'You should now update config/default.nix as needed and '
	notef 'inventory/02_trampoline/hosts with your server IPs'
fi

notef 'Make sure to set your user specific variables in one'
notef 'of the supported ways, see '"$submodule_managed_k8s_name"'/templates/yaook-k8s-env.template.sh'
