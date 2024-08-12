# shellcheck shell=bash

_poetry_common() {
  poetry_dir="$(realpath "${1:-${PWD}}")"
  pyproject_toml="${poetry_dir}/pyproject.toml"
  poetry_lock="${poetry_dir}/poetry.lock"
  watch_file "$pyproject_toml"
  watch_file "$poetry_lock"
}

layout_poetry() {
  _poetry_common "$1"
  if [[ "${NIX_FLAKE_ACTIVE:-""}" == *"$poetry_dir"* ]]; then echo "Flake containing poetry env alreay active. Skipping poetry layout."; return; fi
  poetry_hash="$(sha256sum "$poetry_lock" | cut -d' ' -f1)"
  if [[ "${POETRY_ACTIVE:-""}" == "$poetry_hash" ]]; then echo "Poetry already active. Skipping..."; return; fi
  poetry_extra_args=()
  if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
    cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/yaook-k8s/poetry/minimal-access"
    poetry_extra_args+=("--only" "minimal-access")
    poetry_hash_file="/dev/null"
  else
    cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/yaook-k8s/poetry/$poetry_hash"
    poetry_hash_file="$PWD/.direnv/poetry.lock.sha256"
  fi

  if [[ ! -f "$pyproject_toml" ]]; then
      log_status "No pyproject.toml found. Executing \`poetry init\` to create a \`$pyproject_toml\` first."
      poetry -C "$poetry_dir" init
  fi

  mkdir -p "$cache_dir"
  cp -t "$cache_dir" "$pyproject_toml" "$poetry_lock"

  VIRTUAL_ENV=$(poetry -C "$cache_dir" env info --path 2>/dev/null ; true)

  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
      log_status "No virtual environment exists. Executing \`poetry install\` to create one."
      poetry -C "$cache_dir" install --no-root "${poetry_extra_args[@]}"
      VIRTUAL_ENV=$(poetry -C "$cache_dir" env info --path)
      mkdir -p "$(dirname "$poetry_hash_file")"
      echo "$poetry_hash" > "$poetry_hash_file"
  fi

  if [ "$(cat "$poetry_hash_file")" != "$poetry_hash" ]; then
      echo "poetry.lock changed. Updating virtual env..."
      poetry -C "$cache_dir" install --no-root --sync "${poetry_extra_args[@]}"
      mkdir -p "$(dirname "$poetry_hash_file")"
      echo "$poetry_hash" > "$poetry_hash_file"
  fi

  PATH_add "$VIRTUAL_ENV/bin"
  export POETRY_ACTIVE="$poetry_hash"
  export VIRTUAL_ENV
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
      _poetry_common "${flake_dir}"
      watch_file "${flake_dir}/nix/poetry.nix"
      if [ "${MINIMAL_ACCESS_VENV:-false}" == "true" ]; then
        use flake "${flake_dir}?shallow=1#minimal"
      else
        use flake "${flake_dir}?shallow=1#${YAOOK_K8S_DEVSHELL:-default}"
      fi
      export NIX_FLAKE_ACTIVE="${NIX_FLAKE_ACTIVE}:${flake_dir}"
    else
      echo "Not loading flake. Nix is installed, but flakes are not enabled."
      echo "Add 'experimental-features = flakes nix-command' to either ~/.config/nix/nix.conf or /etc/nix/nix.conf"
    fi
  fi
}
