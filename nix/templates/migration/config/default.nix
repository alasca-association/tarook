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

      master_defaults = {
        flavor = "M";
        image = "Ubuntu 22.04 LTS x64";
      };
      worker_defaults = {
        flavor = "M";
        image = "Ubuntu 22.04 LTS x64";
      };
      gateway_defaults = {
        image = "Debian 12 (bookworm)";
        flavor = "XS";
      };

      public_network = "shared-public-IPv4";
    };
  } (yk8s-lib.importTOML ./config.toml)
