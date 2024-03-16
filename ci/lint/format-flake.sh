#!/usr/bin/env bash
source .envrc.lib.sh

if which nix &>/dev/null && has_flake_support;
then
  nix fmt
fi
