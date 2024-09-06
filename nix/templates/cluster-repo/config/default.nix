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
    # A reference for all available options can be found at
    # https://yaook.gitlab.io/k8s/devel/user/reference/options/index.html
    terraform = {
      enabled = true;

      cluster_name = "devcluster";

      azs = ["AZ1" "AZ2" "AZ3"];

      public_network = "shared-public-IPv4";
      subnet_cidr = "192.168.67.0/24";

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

      nodes = {
        # default: create 3 master and 4 worker nodes
        master-0.role = "master";
        master-1.role = "master";
        master-2.role = "master";
        worker-0.role = "worker";
        worker-1.role = "worker";
        worker-2.role = "worker";
        worker-3.role = "worker";
      };
    };
    kubernetes = {
      version = "1.28.9";
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

