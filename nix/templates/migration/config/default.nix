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
  } (
    # importing an almost unchanged config.toml to prove we're building the same cluster as before
    # TODO: migrate ci config to Nix in the future
    yk8s-lib.importTOML ./config.toml
  )
