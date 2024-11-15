# shellcheck shell=bash

layout_poetry() {
  echo
  echo "WARNING: YAOOK/K8s no longer uses Poetry. Please remove all occurences of 'layout poetry' from your .envrc"
  echo
}

has_flake_support() {
    test -z "$(comm -13 <(nix show-config | grep -Po 'experimental-features = \K(.*)' | tr " " "\n" |  sort) <(echo "flakes nix-command" | tr " " "\n"))"
}

use_flake_if_nix() {
  flake_dir="$(realpath "${1:-${PWD}}")"
  if [[ "${NIX_FLAKE_ACTIVE:-""}" == *"$flake_dir"* ]]; then echo "Flake alreay active. Skipping..."; return; fi
  if has nix; then
    if has_flake_support;
    then
      if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
        source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="
      fi
      if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
        YAOOK_K8S_DEVSHELL="minimal"
      fi
      use flake "${flake_dir}#${YAOOK_K8S_DEVSHELL:-default}"
      watch_file "$flake_dir/nix/dependencies.nix"
      # TODO: watch "$flake_dir/nix/" after manual direnv reload (!1323) is implemented
      export NIX_FLAKE_ACTIVE="${NIX_FLAKE_ACTIVE}:${flake_dir}"
    else
      echo "Not loading flake. Nix is installed, but flakes are not enabled."
      echo "Add 'experimental-features = flakes nix-command' to either ~/.config/nix/nix.conf or /etc/nix/nix.conf"
    fi
  fi
}
