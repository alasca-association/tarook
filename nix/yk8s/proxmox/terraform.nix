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
        version = "~> 0.108.0";
      };
    };
    required_version = ">= 0.14";
  };
  provider.proxmox = {};

  variable.ssh_key.type = "string";

  resource.proxmox_virtual_environment_vm =
    lib.mapAttrs (
      nodeName: nodeConfig:
        builtins.foldl'
        lib.recursiveUpdate {
          on_boot = true;
          operating_system.type = "l26"; # Linux Kernel > 2.6
          cpu.type = "x86-64-v2-AES"; # to allow live migrations between different architectures

          agent.enabled = false; # TODO install with cloud-init
          stop_on_destroy = true;
          reboot_after_update = false; # We don't want to have Proxmox reboot VMs after each Terraform run.
          reboot = false; # Since on Openstack we don't reboot VMs after init, we should keep it off here as well.
          started = true; # Tarook expects that apply-terraform leads to running VMs.
          template = false; # We should not create additional templates.
          tags = ["tarook" nodeConfig.role];
          description = "${nodeConfig.role} node ${nodeName} of Tarook cluster ${config.yk8s.infra.cluster_name}";

          bios = "seabios";

          # Needed for the console inside the Proxmox webinterface
          # which should be available for debugging purposes
          vga = {
            type = "std";
          };
        } [
          nodeConfig.extraConfig
          {
            inherit (cfg) pool_id clone;

            # This is confusing because in Proxmox a "node" is a host on which VMs run and in Tarook on Proxmox, a "node" is a VM on which Kubernetes runs
            name = nodeName; # name of the VM to be created
            node_name = nodeConfig.target_node; # name of the host on which the VM should be created.

            disk =
              [
                {
                  interface = "scsi0";
                  size = nodeConfig.root_disk_size;
                  inherit (cfg) datastore_id;
                  discard = "on";
                }
              ]
              ++ (nodeConfig.extraConfig.disk or []);
            boot_order = ["scsi0"];

            cpu.cores = nodeConfig.cores;
            memory.dedicated = nodeConfig.memory;

            network_device = lib.singleton nodeConfig.network_device;

            initialization = {
              inherit (cfg) datastore_id;
              user_account.keys = [(yk8s-lib.tfRef "var.ssh_key")];
              dns.servers = cfg.dns_servers;
              ip_config =
                # TODO support dhcp / SLAAC
                (lib.optionalAttrs config.yk8s.infra.ipv4_enabled {
                  ipv4 = let
                    inherit (types.yk8s.networking._regexes.cidr) ipv4SuffixRE;
                    inherit (types.yk8s.networking._regexes.rfc952) ipv4AddrRE;
                    subnet_suffix = lib.last (builtins.match "^(${ipv4AddrRE})(${ipv4SuffixRE})$" config.yk8s.infra.subnet_cidr);
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
                  # This allows changes to the template without affecting existing VMs
                  # changing the OS version should be done by destroying and re-creating the VM
                  "clone[0]"
                ];
              }
            ];
          }
        ]
    )
    cfg.nodes;
}
