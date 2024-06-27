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
  recursiveUpdate {
    terraform = {
      cluster_name = "managed-k8s";
    };
  } (yk8s-lib.importTOML ./config.toml)
