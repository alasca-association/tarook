#!/usr/bin/env bash

actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if ! grep --quiet state_directory flake.nix; then
    notef "No state_directory assignment found in flake.nix. Skipping migration."
    exit 0
fi

notef "Trying to patch flake.nix..."

if cat <<'EOF' | git apply --unidiff-zero
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
then
    errorf "Automatic migration failed.
Please remove the following block from ``flake.nix`` in your cluster repository:

    # Don't change this except you know what you're doing
    yk8s.state_directory =
        if builtins.pathExists ./state
        then ./state
        else null;
"
    exit 1
else
    notef "Patch applied successfully"
fi
