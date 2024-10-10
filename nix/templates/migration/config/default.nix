{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
  inherit (lib.attrsets) recursiveUpdate;
in
  recursiveUpdate (
    yk8s-lib.importTOML ./config.toml
  ) {
    # Add any overrides here
  }
