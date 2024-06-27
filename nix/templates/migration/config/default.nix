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
    ## Add your overrides here to incrementally move to Nix
    ## Or use toml2nix to convert the the config in one go, see
    ## https://github.com/cloudandheat/json2nix?tab=readme-ov-file#yaml-and-toml
    ##
    ## Usage: nix run github:cloudandheat/json2nix#toml2nix < config.toml > default.nix
    ##
    ## In order to append the converted config.toml to this file while keeping the curly
    ## braces intact, you may use this oneliner (needs sponge from moreutils):
    ## cat <(head -n -1 default.nix) <(nix run github:cloudandheat/json2nix#toml2nix < config.toml | tail -n +2) | sponge default.nix
  }
