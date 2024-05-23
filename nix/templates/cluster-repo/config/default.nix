{
  pkgs,
  lib,
  yk8s-lib,
  ...
}:
## There are different ways to configure the cluster
###
### Using pure Nix:
###
{
  wireguard = {
    endpoints = {
    };
    peers = {
    };
  };
  vault.cluster_name = "devcluster";
}
###
### Importing from legacy config.toml
###
# yk8s-lib.importTOML ./config.toml
#
###
### Importing from a single YAML file
###
# yk8s-lib.importYAML pkgs ./config.yaml
#
###
### Importing from a tree of YAML files where the file name represents the section
###
# yk8s-lib.importYamlTree pkgs ./tree
#
###
### Importing only certain sections from a config file
###
# let
#   onlySections = sections: cfg: lib.attrsets.filterAttrs (n: _: builtins.elem n sections) cfg;
# in
#   onlySections ["wireguard" "load-balancing" "vault"] (yk8s-lib.importTOML ./config.toml)

