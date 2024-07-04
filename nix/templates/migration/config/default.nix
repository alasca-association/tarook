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
      default_master_image_name = "Ubuntu 22.04 LTS x64";
      default_worker_image_name = "Ubuntu 22.04 LTS x64";
      gateway_image_name = "Debian 12 (bookworm)";

      gateway_flavor = "XS";
      default_master_flavor = "M";
      default_worker_flavor = "M";

      public_network = "shared-public-IPv4";
    };
  } (yk8s-lib.importTOML ./config.toml)
