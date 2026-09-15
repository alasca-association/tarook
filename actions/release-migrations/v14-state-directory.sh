#!/usr/bin/env bash

actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if ! grep --quiet state_directory flake.nix; then
    notef "No state_directory assignment found in flake.nix. Skipping migration."
    exit 0
fi

notef "Trying to patch flake.nix..."

cat <<'EOF' | git apply --unidiff-zero
--- a/flake.nix
+++ b/flake.nix
@@ -1,6 +1,0 @@
-
-        # Don't change this except you know what you're doing
-        yk8s.state_directory =
-          if builtins.pathExists ./state
-          then ./state
-          else null;
EOF

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
    errorf "Automatic migration failed. Please manually remove the following block the ``flake.nix`` file in your cluster repository:

    .. code::

    # Don't change this except you know what you're doing
    yk8s.state_directory =
        if builtins.pathExists ./state
        then ./state
        else null;

    "
    exit 1
fi

notef "Success."
