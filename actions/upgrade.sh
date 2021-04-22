#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [ "$#" != 1 ]; then
    printf 'usage: %s TARGET_VERSION\n\n' "$0" >&2
    printf 'Positional arguments:\n' >&2
    printf '    TARGET_VERSION  The kubernetes version to upgrade to\n' >&2
    exit 2
fi

target_version="$1"
if ! echo "$target_version" | grep -Pq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    # this explicit check is here to ensure that we don’t do any bad things
    # when composing the command line below.
    errorf 'this does not look like a valid Kubernetes version: %q' "$target_version"
    exit 2
fi
minor_version="$(echo "$target_version" | cut -d'.' -f1-2)"
playbook="05_upgrade_to_${minor_version}.yaml"

if [ ! -e "$ansible_playbook/$playbook" ]; then
    errorf 'cannot find an upgrade playbook for target minor version %q' "$minor_version"
    hintf 'I looked for %q' "$ansible_playbook/$playbook"
    exit 2
fi

hintf 'Executing upgrade to version %s (patch level %s)' "$minor_version" "$target_version"

require_disruption

"$actions_dir/wg-up.sh"

cd "$ansible_playbook"
ansible_playbook -i "$ansible_inventoryfile_03" "$playbook" -e "next_k8s_version=$target_version" -e "next_minor_version=$minor_version" -e '{"do_upgrade": true}'
