#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

"$actions_dir/wg-up.sh"

cd "$ansible_playbook"
ansible_playbook -i "$ansible_inventoryfile_03" 03_final.yaml
