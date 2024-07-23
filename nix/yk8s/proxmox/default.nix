{
  pkgs,
  system,
  config,
  lib,
  yk8s-lib,
  terranix-lib,
  ...
}: let
  cfg = config.yk8s.proxmox;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection;
  inherit (yk8s-lib.types) ipv4Cidr ipv4Addr;

  # TODO make this a submodule?
  networkingOptions = {
    ipv4_gateway_address = mkOption {
      type = ipv4Addr;
    };

    subnet_cidr = mkOption {
      type = ipv4Cidr;
    };

    vlan_id = mkOption {
      type = types.ints.between 0 4096;
    };
  };
in {
  options.yk8s.proxmox = mkTopSection {
    enabled = mkOption {
      description = "Proxmox Terraform support";
      type = types.bool;
      default = false;
      apply = v:
        if v && config.yk8s.openstack.enabled
        then throw "ERROR: proxmox.enabled and openstack.enabled are mutually exclusive."
        else v;
    };
    target_nodes = mkOption {
      type = with types; listOf str;
      default = [];
    };

    internal_network = networkingOptions;
    external_network = networkingOptions;

    gateway_defaults = {
      clone_template = mkOption {
        type = types.str;
      };
      cores = mkOption {
        type = types.ints.positive;
        default = 1;
      };
      sockets = mkOption {
        type = types.ints.positive;
        default = 1;
      };
      memory = mkOption {
        type = types.ints.positive;
        default = 1024;
      };
      root_disk_size = mkOption {
        type = types.ints.positive;
        default = 10;
      };
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
      };
    };
    master_defaults = {
      clone_template = mkOption {
        type = types.str;
      };
      cores = mkOption {
        type = types.ints.positive;
        default = 2;
      };
      sockets = mkOption {
        type = types.ints.positive;
        default = 1;
      };
      memory = mkOption {
        type = types.ints.positive;
        default = 4096;
      };
      root_disk_size = mkOption {
        type = types.ints.positive;
        default = 25;
      };
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
      };
    };
    worker_defaults = {
      clone_template = mkOption {
        type = types.str;
      };
      cores = mkOption {
        type = types.ints.positive;
        default = 2;
      };
      sockets = mkOption {
        type = types.ints.positive;
        default = 1;
      };
      memory = mkOption {
        type = types.ints.positive;
        default = 4096;
      };
      root_disk_size = mkOption {
        type = types.ints.positive;
        default = 25;
      };
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
      };
    };
    nodes = mkOption {
      default = {};
      type = types.attrsOf (types.submodule {
        options = {
          role = mkOption {
            type = types.strMatching "gateway|master|worker";
          };
          ipv4_address = mkOption {
            type = ipv4Addr;
          };
          external_ipv4_address = mkOption {
            description = "Only supported for gateway notes";
            type = types.nullOr ipv4Addr;
            default = null;
          };
          ipv6_address = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          external_ipv6_address = mkOption {
            description = "Only supported for gateway notes";
            type = with types; nullOr str;
            default = null;
          };
          target_node = mkOption {
            type = with types; nullOr str;
            default = null;
            apply = v:
              if v == null && cfg.target_nodes == []
              then throw "ERROR: Neither target_nodes nor node.<name>.target_node is set"
              else v;
          };
          clone_template = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          cores = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          sockets = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          memory = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          root_disk_size = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          extraConfig = mkOption {
            type = types.attrs;
            default = {};
          };
        };
      });
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = {};
    };
  };
  config = lib.mkIf cfg.enabled {
    yk8s.terraform.enabled = true;

    yk8s.assertions =
      lib.attrsets.mapAttrsToList (n: v: {
        assertion =
          ((v.role == "gateway") -> (v.external_ipv4_address != null))
          && ((v.role != "gateway") -> (v.external_ipv4_address == null));
        message = "Node ${n}: external_ipv4_addr must be set for gateways and must be unset otherwise";
      })
      cfg.nodes;

    yk8s.infra.subnet_cidr = cfg.internal_network.subnet_cidr;
    yk8s.infra.ansible_hosts = let
      isGateway = nodeName: cfg.nodes.${nodeName}.role == "gateway";
      globalConfig = {
        all.vars = {
          # TODO remove after https://gitlab.com/yaook/k8s/-/merge_requests/1718
          on_openstack = false;
        };
      };
      nodeConfigs =
        lib.mapAttrs (
          nodeName: nodeValues:
            {
              ansible_host =
                if isGateway nodeName
                then nodeValues.external_ipv4_address
                else nodeValues.ipv4_address;
              local_ipv4_address = nodeValues.ipv4_address;
            }
            // lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
              local_ipv6_address = nodeValues.ipv6_address;
            }
        )
        cfg.nodes;
    in
      lib.foldlAttrs (
        acc: nodeName: nodeConfig: let
          path =
            (lib.getAttr cfg.nodes.${nodeName}.role
              {
                "gateway" = ["frontend" "children" "gateways"];
                "master" = ["k8s_nodes" "children" "masters"];
                "worker" = ["k8s_nodes" "children" "workers"];
              })
            ++ ["hosts" "${cfg.nodes.${nodeName}.vm_name}"];
        in
          lib.recursiveUpdate acc (lib.setAttrByPath path nodeConfig)
      )
      globalConfig
      nodeConfigs;
  };
}
