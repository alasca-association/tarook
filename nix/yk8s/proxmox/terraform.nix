cfg: {
  config,
  lib,
  ...
}: let
  mod = a: b: a - b * (a / b);

  matchRoles = {
    gateway = cfg.gateway_defaults;
    master = cfg.master_defaults;
    worker = cfg.worker_defaults;
  };

  inherit (import ./lib.nix {inherit lib;}) mkIpConfig;
  mkProxmoxVM = name: values: let
    inherit (builtins) getAttr;
    mergedValues =
      lib.attrsets.recursiveUpdate
      (getAttr values.role matchRoles)
      (lib.attrsets.filterAttrs (_: v: v != null) values);
    defaults = {
      inherit name;

      onboot = true;

      agent = 1;

      full_clone = true;

      # qemu_os = "l26"; # what does this do?
      cpu = "x86-64-v2-AES";
      scsihw = "virtio-scsi-pci";
      bios = "seabios";

      balloon = 0;

      # bootdisk = "scsi0"; # oder

      vga = {
        type = "std";
      };

      disks.scsi.scsi0.disk = {
        size = mergedValues.root_disk_size;
        cache = "none";
        storage = "ceph1";
        discard = true;
      };

      disks.ide.ide0.cloudinit = {
        storage = "ceph1";
      };

      os_type = "cloud-init";
    };
    networkConfig = lib.mkMerge [
      {
        network =
          [
            {
              bridge = "vmbr2";
              tag = cfg.internal_network.vlan_id;
              firewall = true;
              link_down = false;
              model = "virtio";
            }
          ]
          ++ lib.lists.optional (values.role == "gateway")
          {
            bridge = "vmbr2";
            tag = cfg.external_network.vlan_id;
            firewall = true;
            link_down = false;
            model = "virtio";
          };
        ipconfig0 = mkIpConfig {
          inherit (values) ipv4_address;
          inherit (cfg.internal_network) subnet_cidr ipv4_gateway_address;
        };
      }
      (lib.mkIf (values.role == "gateway") {
        ipconfig1 = mkIpConfig {
          ipv4_address = values.external_ipv4_address;
          inherit (cfg.external_network) subnet_cidr ipv4_gateway_address;
        };
      })
    ];
  in
    lib.mkMerge [
      defaults
      networkConfig
      cfg.extraConfig
      {
        clone = mergedValues.clone_template;
        inherit (mergedValues) cores sockets memory;
        target_node =
          if mergedValues ? target_node
          then mergedValues.target_node
          else null;
        target_nodes =
          if ! mergedValues ? target_node
          then cfg.target_nodes
          else null;
      }
      mergedValues.extraConfig
    ];
in {
  terraform = {
    required_providers = {
      local = {
        source = "hashicorp/local";
        version = ">= 2.4.0";
      };
      proxmox = {
        source = "Telmate/proxmox";
        version = "3.0.1-rc3";
      };
    };
    required_version = ">= 0.14";
  };

  provider.proxmox = {
    pm_log_enable = true;
    pm_log_file = "terraform-plugin-proxmox.log";
    pm_debug = true;
    pm_log_levels = {
      _default = "debug";
      _capturelog = "";
    };
  };
  resource = {
    proxmox_vm_qemu = lib.attrsets.mapAttrs mkProxmoxVM cfg.nodes;
  };
}
