#!/bin/bash

# -E to inherit trap into function calls
set -eEuo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

"$actions_dir/wg-up.sh"

cd "$ansible_playbook"

# see lib.sh
trap do_cleanup_test_on_failure ERR

ansible_playbook -i "$ansible_inventoryfile_03" 04_tests.yaml
