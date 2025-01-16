{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in
  lib.mkMerge [
    {
      terraform = lib.mkDefault {
        cluster_name = "managed-k8s";

        azs = ["AZ1" "AZ2" "AZ3"];

        master_defaults = {
          flavor = "M";
          image = "Ubuntu 24.04 LTS x64";
        };
        worker_defaults = {
          flavor = "M";
          image = "Ubuntu 24.04 LTS x64";
        };
        gateway_defaults = {
          flavor = "XS";
          image = "Debian 12 (bookworm)";
        };

        public_network = "shared-public-IPv4";
      };
    }
    (yk8s-lib.importTOML ./config.toml)
    {
      ## Add your overrides here to incrementally move to Nix
      ## Or use toml2nix to convert the the config in one go, see
      ## https://github.com/cloudandheat/json2nix?tab=readme-ov-file#yaml-and-toml
      ##
      ## Usage: nix run github:cloudandheat/json2nix#toml2nix < config.toml > default.nix
      ##
      ## In order to append the converted config.toml to this file while keeping the curly
      ## braces intact, you may use this oneliner (needs sponge from moreutils):
      ## cat <(head -n -2 default.nix) <(nix run github:cloudandheat/json2nix#toml2nix < config.toml | tail -n +2) <(echo "]") | sponge default.nix; nix run "nixpkgs#alejandra" default.nix
    }
  ]
