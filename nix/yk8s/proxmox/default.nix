{
  config,
  lib,
  yk8s-lib,
  ...
} @ moduleArgs: let
  cfg = config.yk8s.proxmox;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkTopSection mkInternalOption types;

  networkDeviceSubmodule = types.submodule {
    options = {
      # We must list all options here as a
      # workaround for https://github.com/hashicorp/terraform/issues/23347
      # Caused by https://developer.hashicorp.com/terraform/language/attr-as-blocks
      # Will be resolved by upstream https://github.com/bpg/terraform-provider-proxmox/issues/1231
      # Marking most of them as invisible
      bridge = mkOption {
        description = ''
          The name of the network bridge
        '';
        type = types.nonEmptyStr;
        default = "vmbr0";
      };
      firewall = mkOption {
        description = ''
          whether this interface's firewall rules should be used
        '';
        type = with types; nullOr bool;
        default = null;
      };
      model = mkOption {
        visible = false;
        description = ''
          The network device model
        '';
        type = types.enum [
          "e1000"
          "e1000e"
          "rtl8139"
          "virtio"
          "vmxnet3"
        ];
        default = "virtio";
      };
      disconnected = mkOption {
        visible = false;
        readOnly = true; # We can't work with a disconnected network device
        description = ''
          Whether to disconnect the network device from the network
        '';
        type = with types; nullOr bool;
        default = null;
      };
      # Deprecated, thus hardcoded
      enabled = mkInternalOption {
        visible = false;
        readOnly = true;
        default = null;
      };
      mac_address = mkOption {
        visible = false;
        description = ''
          The MAC address.
        '';
        type = with types; nullOr nonEmptyStr;
        default = null;
      };
      mtu = mkOption {
        description = ''
          Force MTU, for VirtIO only. Set to 1 to use the bridge MTU.
          Cannot be larger than the bridge MTU.
        '';
        type = with types; nullOr ints.positive;
        default = null;
      };
      queues = mkOption {
        visible = false;
        description = ''
          The number of queues for VirtIO
        '';
        type = with types; nullOr ints.positive;
        default = null;
      };
      rate_limit = mkOption {
        visible = false;
        description = ''
          The rate limit in megabytes per second.
        '';
        type = with types; nullOr ints.positive;
        default = null;
      };
      trunks = mkOption {
        type = with types; (listOf ints.positive);
        default = [];
        apply = lib.concatMapStringsSep ";" toString;
      };
      vlan_id = mkOption {
        description = ''
          The VLAN identifier
        '';
        type = with types; nullOr (ints.between 0 4096);
        default = null;
      };
    };
  };

  nodeSubmodule = types.submodule {
    options = {
      role = mkOption {
        type = types.enum [
          "master"
          "worker"
        ];
      };
      target_node = mkOption {
        description = ''
          The host on which the VM should be scheduled
        '';
        type = types.nonEmptyStr;
      };
      cores = mkOption {
        description = ''
          How many CPU cores should be assigned to the VM
        '';
        type = types.ints.positive;
        default = 2;
      };
      memory = mkOption {
        description = ''
          How many megabytes of dedicated RAM should be available to the VM.
        '';
        type = types.ints.positive;
        default = 4096;
      };
      root_disk_size = mkOption {
        description = ''
          How big (in gigabytes) should the root disk of the VM be
        '';
        type = types.ints.positive;
        default = 25;
      };
      network_device = mkOption {
        description = ''
          The settings of the VM's primary network device
        '';
        type = networkDeviceSubmodule;
      };
      ipv4_address = mkOption {
        description = ''
          Must be set if config.yk8s.infra.ipv4_enabled==true
        '';
        type = with types; nullOr yk8s.networking.ipv4Addr;
        default = null;
      };
      ipv6_address = mkOption {
        description = ''
          Must be set if config.yk8s.infra.ipv6_enabled==true
        '';
        type = with types; nullOr yk8s.networking.ipv6Addr;
        default = null;
      };
      extraConfig = mkOption {
        description = ''
          Any additional values that the Terraform plugin[1] accepts
          that all VMs should have.

          Note that these are not checked and take precedence over all other values.

          [1] https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
        '';
        type = with types; attrsOf anything;
        default = {};
      };
    };
  };
in {
  options.yk8s.proxmox = mkTopSection {
    _docs.preface = ''
      The environment variable PROXMOX_VE_ENDPOINT needs to be set.

      For authentication, use:
      * Either PROXMOX_VE_USERNAME and PROXMOX_VE_PASSWORD
      * or PROXMOX_VE_API_TOKEN (takes precedence).
    '';
    enabled = mkEnableOption "Proxmox Terraform support";

    ipv4_gateway_address = mkOption {
      description = ''
        Must be set if config.yk8s.infra.ipv4_enabled==true
      '';
      type = with types; nullOr yk8s.networking.ipv4Addr;
      default = null;
    };

    ipv6_gateway_address = mkOption {
      description = ''
        Must be set if config.yk8s.infra.ipv6_enabled==true
      '';
      type = with types; nullOr yk8s.networking.ipv6Addr;
      default = null;
    };

    pool_id = mkOption {
      description = ''
        The identifier for a pool to assign the virtual machines to.
      '';
      type = types.nonEmptyStr;
    };

    datastore_id = mkOption {
      description = ''
        The identifier for the datastore for root disks.
      '';
      type = types.nonEmptyStr;
    };

    clone.vm_id = mkOption {
      description = ''
        The identifier for the VM from which nodes should be cloned. Must be a VM with Ubuntu 24.04 LTS with Cloud-Init support.
      '';
      type = types.ints.positive;
    };

    clone.node_name = mkOption {
      description = ''
        The name of the host on which the source VM resides.
      '';
      type = types.nonEmptyStr;
    };

    nodes = mkOption {
      description = ''
        User defined attribute set of control plane and worker nodes to be created with specified values

        At least one node with role=master must be given.
      '';
      type = with types; attrsOf nodeSubmodule;
      default = {};
    };
  };
  config = lib.mkMerge [
    {
      yk8s.assertions = [
        {
          assertion = !(cfg.enabled && config.yk8s.openstack.enabled);
          message = "ERROR: config.yk8s.proxmox.enabled and config.yk8s.openstack.enabled are mutually exclusive.";
        }
      ];
    }
    (lib.mkIf cfg.enabled {
      yk8s.terraform.enabled = true;

      yk8s.terraform.modules = [(import ./terraform.nix moduleArgs)];

      yk8s._targets.terraform.assertions = [
        {
          assertion = (lib.filterAttrs (_: v: v.role == "master") cfg.nodes) != {};
          message = "config.yk8s.proxmox.nodes: at least one node with role=master must be given.";
        }
        {
          assertion = config.yk8s.infra.ipv4_enabled -> cfg.ipv4_gateway_address != null;
          message = "config.yk8s.proxmox.ipv4_gateway_address must be set if config.yk8s.infra.ipv4_enabled==true";
        }
        {
          assertion = config.yk8s.infra.ipv6_enabled -> cfg.ipv6_gateway_address != null;
          message = "config.yk8s.proxmox.ipv6_gateway_address must be set if config.yk8s.infra.ipv6_enabled==true";
        }
        {
          assertion = config.yk8s.infra.ipv4_enabled -> lib.all (v: v.ipv4_address != null) (lib.attrValues cfg.nodes);
          message = let
            nodesWithoutIpv4Addr = lib.attrNames (lib.filterAttrs (_: v: v.ipv4_address == null) cfg.nodes);
          in
            "config.yk8s.infra.ipv4_enabled==true but the following nodes in config.yk8s.proxmox.nodes are missing an ipv4_address: " + lib.concatStringsSep ", " nodesWithoutIpv4Addr;
        }
        {
          assertion = config.yk8s.infra.ipv6_enabled -> lib.all (v: v.ipv6_address != null) (lib.attrValues cfg.nodes);
          message = let
            nodesWithoutIpv6Addr = lib.attrNames (lib.filterAttrs (_: v: v.ipv6_address == null) cfg.nodes);
          in
            "config.yk8s.infra.ipv6_enabled==true but the following nodes in config.yk8s.proxmox.nodes are missing an ipv6_address: " + lib.concatStringsSep ", " nodesWithoutIpv6Addr;
        }
      ];

      yk8s.infra.ansible_hosts = let
        inherit (config.yk8s.infra) ipv4_enabled ipv6_enabled;
        nodeConfigs =
          lib.mapAttrs (
            nodeName: nodeValues:
              {
                ansible_host =
                  if ipv4_enabled
                  then nodeValues.ipv4_address
                  else nodeValues.ipv6_address;
              }
              // lib.optionalAttrs ipv4_enabled {
                local_ipv4_address = nodeValues.ipv4_address;
              }
              // lib.optionalAttrs ipv6_enabled {
                local_ipv6_address = nodeValues.ipv6_address;
              }
          )
          cfg.nodes;
      in
        {frontend.children.masters = {};}
        // lib.foldlAttrs (
          acc: nodeName: nodeConfig: let
            path = ["${cfg.nodes.${nodeName}.role}s" "hosts" nodeName];
          in
            lib.recursiveUpdate acc (lib.setAttrByPath path nodeConfig)
        )
        {}
        nodeConfigs;
    })
  ];
}
