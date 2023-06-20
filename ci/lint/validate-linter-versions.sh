#!/usr/bin/env bash

precom=".pre-commit-config.yaml"
glci=".gitlab-ci.yml"
error=false

errmsg() {
  echo "$1 version differs between $precom and $glci."
  error=true
}

pre_commit_version() {
  # < "$precom" yq '.repos[] | select( .repo=="'"$1"'")| .rev' -r
  grep -A1 "$1" .pre-commit-config.yaml | grep -Po 'rev: \K(.*)'
}

gitlab_ci_pip_version() {
  grep -Po '"pip3 install '"$1"'==\K(.*)(?=")' "$glci"
}

if [ "$(gitlab_ci_pip_version yamllint)" != "$(pre_commit_version "https://github.com/adrienverge/yamllint")" ]; then
  errmsg yamllint
fi

if [ "$(gitlab_ci_pip_version flake8)" != "$(pre_commit_version "https://github.com/pycqa/flake8")" ]; then
  errmsg flake8
fi


if [ "$(grep -Po '/koalaman/shellcheck-alpine:\K(.*)(?=")' "$glci")" != "$(pre_commit_version "https://github.com/koalaman/shellcheck-precommit")" ]; then
  errmsg shellcheck
fi


if [ "$error" = true ]; then
  exit 1
fi
