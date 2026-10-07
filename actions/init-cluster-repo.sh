#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

submodule_managed_k8s_url="${MANAGED_K8S_GIT:-https://gitlab.com/alasca.cloud/tarook/tarook.git}"
submodule_managed_k8s_branch_default="release/v$version_major_minor"

usage() {
    >&2 echo "Usage: nix run <flake-url>#init -- [-b BRANCH] TEMPLATE"
    >&2 echo ""
    >&2 echo "Arguments:"
    >&2 echo "    -b BRANCH   Tarook branch to checkout in git submodule"
    >&2 echo "    TEMPLATE    Flavor of initial configuration to setup"
    >&2 echo "                One of: $(cluster_repo_template_list)"
}

# Parse commandline arguments
args=("$@")
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b)
            arg_branch="$2"
            shift 2
            ;;
        *)
            other_args+=( "$1" )
            shift 1
            ;;
    esac
done

# Set branch from commandline or `managed_k8s_git_branch` envvar or to default
if [[ "${arg_branch+x}" == "x" ]]; then
    branch="${arg_branch}"
# TODO: @deprecated::v14.0
#       Once Tarook v14.0 is not supported anymore, this elif block shall be removed
elif [[ "${managed_k8s_git_branch+x}" == "x" ]]; then
    branch="${managed_k8s_git_branch}"
else
    branch="${submodule_managed_k8s_branch_default}"
fi

# Switch to flake of the given branch
# if we did not already switch
# NOTE: There should be no initialization logic before this, in order to ensure compatibility with all branches that provide #init
if
  (
    [[ "${arg_branch+x}" == "x" ]] \
    || [[ -z "${managed_k8s_git_branch:-${branch}}" ]]
  ) \
  && (
    [[ "${managed_k8s_init_no_flake_switch@a}" == *x* ]] \
    && [[ "${managed_k8s_init_no_flake_switch}" != "true" ]]
  )
then
    url="git+${submodule_managed_k8s_url}?ref=${branch}"
    >&2 echo "Executing init script from ${url}"

    managed_k8s_latest_release=false \
    managed_k8s_git_branch="${branch}" \
    managed_k8s_init_no_flake_switch=true \
      exec nix run "${url}#init" -- "${other_args[@]}"
fi
# TODO: @deprecated::v14.0
#       Once Tarook v14.0, which introduced the -b option, is not supported anymore,
#       the block above shall be replaced with the following one.
#if [[ "${managed_k8s_init_no_flake_switch@a}" == *x* ]] \
#&& [[ "${managed_k8s_init_no_flake_switch}" != "true" ]]; then
#    url="git+${submodule_managed_k8s_url}?ref=${branch}"
#    >&2 echo "Executing init script from ${url}"
#
#    managed_k8s_init_no_flake_switch=true \
#      exec nix run "${url}#init" -- "${args[@]}"
#fi

other_args_num=1
if [ "${#other_args[@]}" -ne "$other_args_num" ]; then
    errorf "Expecting $other_args_num argument(s), but ${#other_args[@]} were given"
    echo >&2
    usage
    exit 2
fi

template="${other_args[0]}"


### initialization logic

check_nix_version

if [[ "$template" == */* || ! -e "${cluster_repo_template_dir:?}/${template:?}" ]]; then
    errorf "Unsupported template."
    hintf "Currently supported templates: $(cluster_repo_template_list)"
    exit 1
fi

submodule_base="submodules"


if [ ! "$actions_dir" == "./$submodule_managed_k8s_name/actions" ]; then
    if [ ! -d "$submodule_managed_k8s_name" ]; then
        # Checkout specified branch

        echo ''
        notef "Adding $submodule_managed_k8s_name submodule on branch $branch..."

        run git submodule add -b "$branch" "$submodule_managed_k8s_url" "$submodule_managed_k8s_name"
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

notef 'cluster repository initialised successfully!'
notef 'You should now update config/default.nix as needed and '
notef 'then run git commit -v to check and commit your changes'

notef 'Make sure to set your user specific variables in one'
notef 'of the supported ways, see '"$submodule_managed_k8s_name"'/templates/yaook-k8s-env.template.sh'
