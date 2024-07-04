{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in
  ## There are different ways to configure the cluster
  ###
  ### Using pure Nix:
  ###
  {
    terraform = {
      enabled = true;

      cluster_name = "devcluster";

      masters = 3;
      workers = 3;

      subnet_cidr = "192.168.67.0/24";

      default_master_image_name = "Ubuntu 22.04 LTS x64";
      default_worker_image_name = "Ubuntu 22.04 LTS x64";
      gateway_image_name = "Debian 12 (bookworm)";

      gateway_flavor = "XS";
      default_master_flavor = "M";
      default_worker_flavor = "M";

      azs = ["AZ1" "AZ2" "AZ3"];
      public_network = "shared-public-IPv4";
    };
    wireguard = {
      enabled = true;
      endpoints = [
        {
          id = 0;
          ip_cidr = "172.30.153.64/26";
          ip_gw = "172.30.153.65/26";
        }
      ];
      peers = [
        {
          ident = "example.name";
          pub_key = "XXXX";
        }
      ];
    };
    vault.cluster_name = cfg.terraform.cluster_name;
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

