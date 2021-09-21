#!/bin/bash
set -xeuo pipefail

echo "the config.toml and env_file should already in the git lab project. See the readme.md for more details"
export submodule_managed_k8s_name=managed-k8s
export submodule_wg_users_name=wg_user

env_file=env.sh
if [ ! -f "$env_file" ]; then
    echo "$env_file does not exist"
    exit 1
fi
config_file=config/config.toml
if [ ! -f "$config_file" ]; then
    echo "$config_file does not exist"
    exit 1
fi

# shellcheck source=jenkins/env.template.sh
source "$env_file"
echo "Operation: $operation"

if [ ! -d "$submodule_managed_k8s_name" ]; then
  git submodule add "$submodule_managed_k8s_git"
  mkdir terraform
  mkdir inventory
fi

#load wg_user (internal)
if [ ! -d "$submodule_wg_users_name" ]; then
  git submodule add "$submodule_wg_user_git"
fi

#update submodule
git submodule update --init --recursive

## cp template.gitignore file
cp "$submodule_managed_k8s_name"/jenkins/template.gitignore .gitignore

## read config
python3 "$submodule_managed_k8s_name"/jenkins/toml_helper.py

./managed-k8s/actions/"$operation.sh"

git add .gitmodules
git add config/
git add terraform/
git add inventory/
git commit -m"$operation cluster $cluster_name"
git push
