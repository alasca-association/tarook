{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in {
  yk8s =
    ## There are different ways to configure the cluster
    ###
    ### Using pure Nix:
    ###
    {
      # A reference for all available options can be found at
      # https://docs.tarook.cloud/devel/user/reference/options/index.html
      infra = {
        cluster_name = "devcluster";
        subnet_cidr = "192.168.67.0/24";
      };

      openstack = {
        enabled = true;

        azs = ["AZ1" "AZ2" "AZ3"];

        public_network = "shared-public-IPv4";

        master_defaults = {
          flavor = "M";
          image = "Ubuntu 24.04 LTS x64";
        };
        worker_defaults = {
          flavor = "M";
          image = "Ubuntu 24.04 LTS x64";
        };
        gateway_defaults = {
          image = "Debian 12 (bookworm)";
          flavor = "XS";
        };

        nodes = {
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
        # NOTE: The following comment is needed for Tarook's dependency
        #       management which keeps the Kubernetes version up-to-date with
        #       renovate-bot. Safe to remove.
        # renovate: datasource=github-releases packageName=kubernetes/kubernetes
        version = "1.33.12";
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
          # {
          #   ident = "example.name";
          #   pub_key = "ExampleWgKeyLiKUsKjhSDY9u06pX68rbdg4V6dkHFo=";
          # }
        ];
      };
    };
  ###
  ### Importing from a single TOML file
  ###
  # yk8s-lib.importTOML ./config.toml;
  #
  ###
  ### Importing from a single YAML file
  ###
  # yk8s-lib.importYAML pkgs ./config.yaml;
  #
  ###
  ### Importing only certain sections from a single TOML file
  ###
  # lib.getAttrs ["wireguard" "load-balancing" "vault"] (yk8s-lib.importTOML ./config.toml);
}
