# shellcheck shell=bash

layout_poetry() {
  echo
  echo "WARNING: Tarook no longer uses Poetry. Please remove all occurences of 'layout poetry' from your .envrc"
  echo
}

has_flake_support() {
    test -z "$(comm -13 <(nix show-config 2>/dev/null | grep -Po 'experimental-features = \K(.*)' | tr " " "\n" |  sort) <(echo "flakes nix-command" | tr " " "\n"))"
}

_nix_flake_auto() {
  if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
    source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="
  fi
  use flake "${flake_dir}#${YAOOK_K8S_DEVSHELL}"
}

_nix_flake_manual() {
  layout_dir=$(direnv_layout_dir)
  mkdir -p "$layout_dir"
  nix_hash_file="$layout_dir/nix_flake.sha256"
  hash_command="echo '#' devshell: ${YAOOK_K8S_DEVSHELL}; find $flake_dir/nix -type f -exec sha256sum {} +"
  reload_command="yaook-direnv-reload"
  watch_file "$nix_hash_file"
  nix_hashes="$(bash -c "$hash_command")"

  bin_dir="$layout_dir/bin"
  mkdir -p "$bin_dir"
  PATH_add "$bin_dir"

  out_path="$layout_dir/yaook-devshell/$flake_dir"
  PATH_add "$out_path/bin"

  cat << EOF > "$bin_dir/$reload_command"
#!/usr/bin/env bash
set -e
if [[ ! -d "$PWD" ]] || [[ "\$(realpath "\$(dirname \$0)/../..")" != "$PWD" ]]; then
  echo "Cannot find source directory; Did you move it?"
  echo "(Looking for "$PWD")"
  echo 'Cannot force reload with this script - use "direnv reload" manually and then try again'
  exit 1
fi

rm -f "$out_path" 2>/dev/null
nix build "$flake_dir#yk8s-env-${YAOOK_K8S_DEVSHELL}" -o "$out_path"
bash -c "$hash_command" > "$nix_hash_file"
EOF
  chmod +x "$bin_dir/$reload_command"

  if [ "$(cat "$nix_hash_file" 2>/dev/null)" != "$nix_hashes" ]; then
    echo "========"
    echo "WARNING: Flake changed. Update environment by running $reload_command"
    echo "========"
  elif [ -L "$out_path" ] && ! [ -e "$out_path"  ]; then
    echo "========"
    echo "WARNING: Flake environment has been garbage collected. Please rebuild by running $reload_command"
    echo "========"
  fi
}

use_flake_if_nix() {
  flake_dir="$(realpath "${1:-${PWD}}")"
  if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
    YAOOK_K8S_DEVSHELL="minimal"
  fi
  YAOOK_K8S_DEVSHELL=${YAOOK_K8S_DEVSHELL:-default}

  if [[ "${NIX_FLAKE_ACTIVE:-""}" == *"$flake_dir"* ]]; then echo "Flake alreay active. Skipping..."; return; fi

  if ! has nix; then return; fi

  if ! has_flake_support; then
    echo "Not loading flake. Nix is installed, but flakes are not enabled."
    echo "Add 'experimental-features = flakes nix-command' to either ~/.config/nix/nix.conf or /etc/nix/nix.conf"
    return
  fi

  if [ "${YAOOK_K8S_DIRENV_MANUAL:-false}" == "true" ]; then
    _nix_flake_manual "$flake_dir"
    watch_file "$flake_dir/nix"
  else
    _nix_flake_auto "$flake_dir"
    # for auto-reload, only watch the file most likely to update dependencies
    # otherwise the reload frequency would not be bearable
    watch_file "$flake_dir/nix/dependencies.nix"
  fi
  export NIX_FLAKE_ACTIVE="${NIX_FLAKE_ACTIVE}:${flake_dir}"

  use locale_archive_if_not_set "$flake_dir"
}

use_locale_archive_if_not_set() {
  flake_dir="$(realpath "${1:-${PWD}}")"
  if [ -z "$LOCALE_ARCHIVE" ]; then
    echo "Setting locale-archive"
    layout_dir=$(direnv_layout_dir)
    export LOCALE_ARCHIVE="$layout_dir/lib/locale/locale-archive"
    mkdir -p "$(dirname "$LOCALE_ARCHIVE")"

    if ! [ -e "$LOCALE_ARCHIVE" ]; then
      echo "Building locale-archive"
      out_path="$(nix build --print-out-paths "$flake_dir#glibcLocales")"
      rm -f "$LOCALE_ARCHIVE"
      ln -s "$out_path/lib/locale/locale-archive" "$LOCALE_ARCHIVE"
    fi
  fi
}

layout_yaook-k8s() {
  flake_dir="$(realpath "${1:-managed-k8s}")"
  user_env="$HOME/.config/yaook-k8s/env"
  if [ -e "$user_env" ]; then
    source_env "$user_env"
  else
    echo "WARNING: $user_env was not found. It is likely that user-specific variables are not set."
    echo "See https://docs.tarook.cloud/devel/user/reference/environmental-variables.html#minimal-required-changes"
  fi
  if [ -e .envrc.local ]; then source_env .envrc.local; fi
  use flake_if_nix "$flake_dir"
  use locale_archive_if_not_set "$flake_dir"
}
