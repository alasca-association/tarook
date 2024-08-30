# shellcheck shell=bash
layout_poetry() {
  poetry_dir="$(realpath "${1:-${PWD}}")"
  mkdir -p "$PWD/.direnv"
  PYPROJECT_TOML="${PYPROJECT_TOML:-${poetry_dir}/pyproject.toml}"
  poetry_file="${poetry_dir}/poetry.lock"
  poetry_hash="$(sha256sum "$poetry_file" | cut -d' ' -f1)"
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

  if [[ ! -f "$PYPROJECT_TOML" ]]; then
      log_status "No pyproject.toml found. Executing \`poetry init\` to create a \`$PYPROJECT_TOML\` first."
      poetry -C "$poetry_dir" init
  fi

  mkdir -p "$cache_dir"
  cp -t "$cache_dir" "$PYPROJECT_TOML" "$poetry_file"

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
  watch_file "$PYPROJECT_TOML"
  watch_file "$poetry_dir/poetry.lock"
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
      use flake "${flake_dir}#${YAOOK_K8S_DEVSHELL:-default}"
      export NIX_FLAKE_ACTIVE="${NIX_FLAKE_ACTIVE}:${flake_dir}"
    else
      echo "Not loading flake. Nix is installed, but flakes are not enabled."
      echo "Add 'experimental-features = flakes nix-command' to either ~/.config/nix/nix.conf or /etc/nix/nix.conf"
    fi
  fi
}
