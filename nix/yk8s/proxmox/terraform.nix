{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.proxmox;

  inherit (yk8s-lib) types tfRef;
  mkCloudConfig = name: attrs:
    yk8s-lib.withPreamble ''
      #cloud-config

    ''
    name (yk8s-lib.mkYaml name attrs);
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
  resource.proxmox_virtual_environment_file = lib.optionalAttrs cfg.cloud_config.enabled (
    lib.mapAttrs' (nodeName: nodeConfig: {
      name = "${nodeName}-cloud-config";
      value = {
        content_type = "snippets";
        inherit (cfg.cloud_config) datastore_id;
        node_name = nodeConfig.target_node;

        overwrite = false;
        source_file = let
          file_name = "${nodeName}.cloud-config.yaml"; # TODO derive filename from (clustername, nodename, hash) to prevent collisions
        in {
          inherit file_name;
          path =
            (mkCloudConfig file_name {
              packages = ["qemu-guest-agent"];
            }).outPath;
        };
      };
    })
    cfg.nodes
  );
  resource.proxmox_virtual_environment_vm =
    lib.mapAttrs (
      nodeName: nodeConfig:
        lib.recursiveUpdate {
          name = nodeName;

          on_boot = true;
          operating_system.type = "l26"; # Linux Kernel > 2.6

          agent.enabled = cfg.cloud_config.enabled;
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
          initialization =
            {
              inherit (cfg) datastore_id;
              # user_account.keys = [(yk8s-lib.tfRef "var.ssh_key")]; # TODO conflicts with user_data_file_id https://registry.terraform.io/providers/bpg/proxmox/0.78.0/docs/resources/virtual_environment_vm#user_account-3
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
            }
            // lib.optionalAttrs cfg.cloud_config.enabled {
              user_data_file_id = tfRef "proxmox_virtual_environment_file.${nodeName}-cloud-config.id";
            };
          lifecycle = [
            {
              ignore_changes = [
                "initialization"
                "clone[0].node_name"
              ];
            }
          ];
        }
        nodeConfig.extraConfig
    )
    cfg.nodes;
}
