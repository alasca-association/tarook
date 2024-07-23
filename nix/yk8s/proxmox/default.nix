{
  config,
  pkgs,
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
        type = types.bool;
        default = false;
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
        default = false;
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
        type = with types; nullOr (ints.between 1 64);
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
        description = ''
          List of VLAN trunks (``[10 20 30]``).
          Note that the VLAN-aware feature need to be enabled on the PVE Linux Bridge to use trunks.
        '';
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
          Host onto which to schedule the VM
        '';
        type = types.nonEmptyStr;
      };
      cores = mkOption {
        description = ''
          Amount of CPU cores to be assigned to the VM
        '';
        type = types.ints.positive;
      };
      memory = mkOption {
        description = ''
          Amount of dedicated RAM in megabytes to be assigned to the VM
        '';
        type = types.ints.positive;
      };
      root_disk_size = mkOption {
        description = ''
          Amount of root disk capacity in gigabytes to be assigned to the VM
        '';
        type = types.ints.positive;
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
          Any additional values
          that the ``bpg/proxmox`` Terraform provider plugin accepts
          for a VM.
          See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm

          Note that these are not checked and cannot override values set by other options.
          Note that setting ``user_data_file_id`` is currently not supported.
        '';
        type = with types; attrsOf anything;
        default = {};
      };
    };
  };
in {
  options.yk8s.proxmox = mkTopSection {
    _docs.preface = ''
      See :ref:`Proxmox Credentials <environmental-variables.proxmox-credentials>` for the environment variables necessary for Proxmox.
    '';

    enabled = mkOption {
      description = ''
        Whether to build the cluster on top of Proxmox

        .. note::

          Proxmox support is currently in ALPHA state. There are no guarantees towards stability or compatibility yet. In particular: Configuration may change in a breaking manner even in patch versions.

      '';
      type = types.bool;
      default = false;
    };

    ipv4_gateway_address = mkOption {
      description = ''
        The IPv4 address that should be configured as the default gateway on each node.

        Must be set if config.yk8s.infra.ipv4_enabled==true
      '';
      type = with types; nullOr yk8s.networking.ipv4Addr;
      default = null;
    };

    ipv6_gateway_address = mkOption {
      description = ''
        The IPv6 address that should be configured as the default gateway on each node.

        Must be set if config.yk8s.infra.ipv6_enabled==true
      '';
      type = with types; nullOr yk8s.networking.ipv6Addr;
      default = null;
    };

    dns_servers = mkOption {
      type = with types; listOf (either yk8s.networking.ipv4Addr yk8s.networking.ipv6Addr);
      default =
        (lib.optional config.yk8s.infra.ipv4_enabled cfg.ipv4_gateway_address)
        ++ (lib.optional config.yk8s.infra.ipv6_enabled cfg.ipv6_gateway_address);
      defaultText = lib.literalExpression ''
        (lib.optional config.yk8s.infra.ipv4_enabled config.yk8s.proxmox.ipv4_gateway_address)
        ++ (lib.optional config.yk8s.infra.ipv6_enabled config.yk8s.proxmox.ipv6_gateway_address)
      '';
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
      type = types.ints.between 100 999999999;
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
          message = "config.yk8s.proxmox.enabled: is mutually exclusive with config.yk8s.openstack.enabled";
        }
      ];
    }
    (lib.mkIf cfg.enabled {
      yk8s.terraform.enabled = true;

      yk8s.terraform.modules = [(import ./terraform.nix moduleArgs)];

      yk8s._pythonIFD.functions.proxmoxAssertions_areIPAddressesInSubnet = {
        arg = let
          inherit (config.yk8s.infra) ipv4_enabled ipv6_enabled subnet_cidr subnet_v6_cidr;
        in {
          ipv4 = lib.optionalAttrs config.yk8s.infra.ipv4_enabled {
            cidr = subnet_cidr;
            gatewayAddr = cfg.ipv4_gateway_address;
            nodeAddrs = lib.mapAttrs (_: v: v.ipv4_address) cfg.nodes;
          };
          ipv6 = lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
            cidr = subnet_v6_cidr;
            gatewayAddr = cfg.ipv6_gateway_address;
            nodeAddrs = lib.mapAttrs (_: v: v.ipv6_address) cfg.nodes;
          };
        };
        body = ''
          from ipaddress import ip_address, ip_network

          def check_addrs(v):
              subnet = ip_network(v["cidr"], strict=False)
              return {
                  "gatewayAddr": None if v["gatewayAddr"] is None else (ip_address(v["gatewayAddr"]) in subnet),
                  "nodeAddrs": {
                      node: None if addr is None else (ip_address(addr) in subnet)
                      for node, addr in v["nodeAddrs"].items()
                  }
              }

          return {
              ip_family: check_addrs(v) for ip_family, v in arg.items() if v != {} and v["cidr"] is not None
          }
        '';
      };
      yk8s._targets.terraform.assertions =
        [
          {
            assertion = (lib.filterAttrs (_: v: v.role == "master") cfg.nodes) != {};
            message = "config.yk8s.proxmox.nodes: at least one node with role=master must be given.";
          }
          {
            assertion = config.yk8s.infra.ipv4_enabled -> cfg.ipv4_gateway_address != null;
            message = "config.yk8s.proxmox.ipv4_gateway_address: is null but config.yk8s.infra.ipv4_enabled==true";
          }
          {
            assertion = config.yk8s.infra.ipv6_enabled -> cfg.ipv6_gateway_address != null;
            message = "config.yk8s.proxmox.ipv6_gateway_address: is null but config.yk8s.infra.ipv6_enabled==true";
          }
          (let
            duplicateIpv4Addrs = lib.pipe cfg.nodes [
              (lib.filterAttrs (_: v: v.ipv4_address != null))
              (lib.mapAttrsToList lib.nameValuePair)
              (lib.lists.groupBy (node: node.value.ipv4_address))
              (lib.filterAttrs (_: nodes: lib.length nodes > 1))
            ];
          in {
            assertion = lib.length (lib.attrNames duplicateIpv4Addrs) == 0;
            message = let
              duplicates = lib.concatStringsSep "; " (
                lib.mapAttrsToList (
                  addr: nodes: "${addr} for <name>=(${lib.concatStringsSep ", " (lib.map (node: node.name) nodes)})"
                )
                duplicateIpv4Addrs
              );
            in
              lib.concatStrings [
                "config.yk8s.proxmox.nodes.<name>.ipv4_address:"
                " Duplicate value: ${duplicates}"
              ];
          })
          (let
            duplicateIpv6Addrs = lib.pipe cfg.nodes [
              (lib.filterAttrs (_: v: v.ipv6_address != null))
              (lib.mapAttrsToList lib.nameValuePair)
              (lib.lists.groupBy (node: node.value.ipv6_address))
              (lib.filterAttrs (_: nodes: lib.length nodes > 1))
            ];
          in {
            assertion = lib.length (lib.attrNames duplicateIpv6Addrs) == 0;
            message = let
              duplicates = lib.concatStringsSep "; " (
                lib.mapAttrsToList (
                  addr: nodes: "${addr} for <name>=(${lib.concatStringsSep ", " (lib.map (node: node.name) nodes)})"
                )
                duplicateIpv6Addrs
              );
            in
              lib.concatStrings [
                "config.yk8s.proxmox.nodes.<name>.ipv6_address:"
                " Duplicate value: ${duplicates}"
              ];
          })
          {
            assertion = let
              gatewayV4AddrInSubnet = config.yk8s._pythonIFD.outputs.proxmoxAssertions_areIPAddressesInSubnet.ipv4.gatewayAddr or null;
            in
              gatewayV4AddrInSubnet != null -> gatewayV4AddrInSubnet;
            message = lib.concatStrings [
              "config.yk8s.proxmox.ipv4_gateway_address:"
              " ${cfg.ipv4_gateway_address} is not in ${config.yk8s.infra.subnet_cidr} (config.yk8s.infra.subnet_cidr)"
            ];
          }
          {
            assertion = let
              gatewayV6AddrInSubnet = config.yk8s._pythonIFD.outputs.proxmoxAssertions_areIPAddressesInSubnet.ipv6.gatewayAddr or null;
            in
              gatewayV6AddrInSubnet != null -> gatewayV6AddrInSubnet;
            message = lib.concatStrings [
              "config.yk8s.proxmox.ipv6_gateway_address:"
              " ${cfg.ipv6_gateway_address} is not in ${config.yk8s.infra.subnet_v6_cidr} (config.yk8s.infra.subnet_v6_cidr)"
            ];
          }
        ]
        # per-node assertions
        ++ (lib.flatten (lib.mapAttrsToList (nodeName: nodeOptions: [
            {
              assertion =
                config.yk8s.infra.ipv4_enabled -> nodeOptions.ipv4_address != null;
              message = lib.concatStrings [
                "config.yk8s.proxmox.nodes.${nodeName}.ipv4_address:"
                " is null but config.yk8s.infra.ipv4_enabled==true"
              ];
            }
            {
              assertion =
                config.yk8s.infra.ipv6_enabled -> nodeOptions.ipv6_address != null;
              message = lib.concatStrings [
                "config.yk8s.proxmox.nodes.${nodeName}.ipv6_address:"
                " is null but config.yk8s.infra.ipv6_enabled==true"
              ];
            }
            {
              assertion = let
                nodeV4AddrInSubnet = config.yk8s._pythonIFD.outputs.proxmoxAssertions_areIPAddressesInSubnet.ipv4.nodeAddrs.${nodeName} or null;
              in
                nodeV4AddrInSubnet != null -> nodeV4AddrInSubnet;
              message = lib.concatStrings [
                "config.yk8s.proxmox.nodes.${nodeName}.ipv4_address:"
                " ${nodeOptions.ipv4_address} is not in ${config.yk8s.infra.subnet_cidr} (config.yk8s.infra.subnet_cidr)"
              ];
            }
            {
              assertion = let
                nodeV6AddrInSubnet = config.yk8s._pythonIFD.outputs.proxmoxAssertions_areIPAddressesInSubnet.ipv6.nodeAddrs.${nodeName} or null;
              in
                nodeV6AddrInSubnet != null -> nodeV6AddrInSubnet;
              message = lib.concatStrings [
                "config.yk8s.proxmox.nodes.${nodeName}.ipv6_address:"
                " ${nodeOptions.ipv6_address} is not in ${config.yk8s.infra.subnet_v6_cidr} (config.yk8s.infra.subnet_v6_cidr)"
              ];
            }
          ])
          cfg.nodes));

      yk8s._targets.terraform.warnings =
        # Warn about reserved VLAN IDs 0 and 4095
        lib.pipe cfg.nodes [
          (lib.filterAttrs (
            _: nodeOptions:
              (nodeOptions.network_device.vlan_id == 0)
              || (nodeOptions.network_device.vlan_id == 4095)
          ))
          (lib.mapAttrsToList (
            nodeName: nodeOptions:
              lib.concatStrings [
                "config.yk8s.proxmox.nodes.${nodeName}.network_device.vlan_id:"
                " ${toString nodeOptions.network_device.vlan_id} is a reserved VLAN ID"
              ]
          ))
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
