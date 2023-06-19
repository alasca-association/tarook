# shellcheck shell=bash
layout_poetry() {
  poetry_dir="${1:-${PWD}}"
  PYPROJECT_TOML="${PYPROJECT_TOML:-${poetry_dir}/pyproject.toml}"
  if [[ ! -f "$PYPROJECT_TOML" ]]; then
      log_status "No pyproject.toml found. Executing \`poetry init\` to create a \`$PYPROJECT_TOML\` first."
      poetry -C "$poetry_dir" init
  fi

  VIRTUAL_ENV=$(poetry -C "$poetry_dir" env info --path 2>/dev/null ; true)

  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
      log_status "No virtual environment exists. Executing \`poetry install\` to create one."    
      poetry -C "$poetry_dir" install
      VIRTUAL_ENV=$(poetry -C "$poetry_dir" env info --path)
  fi

  PATH_add "$VIRTUAL_ENV/bin"
  export POETRY_ACTIVE=1
  export VIRTUAL_ENV
  watch_file "$PYPROJECT_TOML"
  watch_file "$poetry_dir/poetry.lock"
}
