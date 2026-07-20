#!/usr/bin/env bash

actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if ! grep state_directory flake.nix &>/dev/null; then
    notef "No state_directory assignment found in flake.nix. Skipping migration."
    exit 0
fi

notef "Trying to patch flake.nix..."

cat <<'EOF' | git apply &>/dev/null
diff --git a/flake.nix b/flake.nix
index fdfdc1c67..a03cea27f 100644
--- a/flake.nix
+++ b/flake.nix
@@ -22,9 +22,3 @@
         formatter = inputs.yk8s.packages.${system}.alejandra-tree;
         imports = [./config];
-
-        # Don't change this except you know what you're doing
-        yk8s.state_directory =
-          if builtins.pathExists ./state
-          then ./state
-          else null;
       };
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
