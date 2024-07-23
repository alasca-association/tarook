{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.proxmox;

  inherit (yk8s-lib) types;
in {
  terraform = {
    required_providers = {
      proxmox = {
        source = "bpg/proxmox";
        version = "~> 0.78";
      };
    };
    required_version = ">= 0.14";
  };
  provider.proxmox = {};
  variable.ssh_key.type = "string";
  resource.proxmox_virtual_environment_vm =
    lib.mapAttrs (
      nodeName: nodeConfig:
        lib.recursiveUpdate {
          name = nodeName;

          on_boot = true;
          operating_system.type = "l26"; # Linux Kernel > 2.6

          agent.enabled = false; # TODO install with cloud-init
          stop_on_destroy = true;

          bios = "seabios";

          vga = {
            type = "std";
          };

          disk = [
            {
              interface = "scsi0";
              size = nodeConfig.root_disk_size;
              inherit (cfg) datastore_id;
              discard = "on";
            }
          ];
          boot_order = ["scsi0"];
          inherit (cfg) pool_id clone;
          cpu.cores = nodeConfig.cores;
          cpu.type = "x86-64-v2-AES";
          memory.dedicated = nodeConfig.memory;
          node_name = nodeConfig.target_node;
          network_device = lib.singleton nodeConfig.network_device;
          initialization = {
            inherit (cfg) datastore_id;
            user_account.keys = [(yk8s-lib.tfRef "var.ssh_key")];
            ip_config =
              # TODO support dhcp / SLAAC
              (lib.optionalAttrs config.yk8s.infra.ipv4_enabled {
                ipv4 = let
                  inherit (types.yk8s.networking._regexes.cidr) ipv4SuffixRE;
                  inherit (types.yk8s.networking._regexes.rfc952) ipv4AddrRE;
                  subnet_suffix = lib.last (builtins.match "^${ipv4AddrRE}(${ipv4SuffixRE})$" config.yk8s.infra.subnet_cidr);
                in {
                  address = "${nodeConfig.ipv4_address}/${subnet_suffix}";
                  gateway = cfg.ipv4_gateway_address;
                };
              })
              // (lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
                ipv6 = let
                  inherit (types.yk8s.networking._regexes.cidr) ipv6SuffixRE;
                  inherit (types.yk8s.networking._regexes.rfc3513) ipv6AddressRE;
                  subnet_suffix = lib.last (builtins.match "^${ipv6AddressRE}(${ipv6SuffixRE})$" config.yk8s.infra.subnet_v6_cidr);
                in {
                  address = "${nodeConfig.ipv6_address}/${subnet_suffix}";
                  gateway = cfg.ipv6_gateway_address;
                };
              });
          };
          lifecycle = [
            {
              ignore_changes = [
                "clone[0].node_name"
              ];
            }
          ];
        }
        nodeConfig.extraConfig
    )
    cfg.nodes;
}
