{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
  scheduling_key_prefix = "scheduling.mk8s.cloudandheat.com";
in {
  # Some values need to be changed during CI runs, so we use an override file
  imports = [./overrides.nix];

  config.yk8s = {
    infra = {
      cluster_name = "ci";
    };
    openstack.enabled = false;
    wireguard.enabled = false;
    proxmox = {
      enabled = true;
      ipv4_gateway_address = "192.168.106.1";
      pool_id = "Tarook-Dev";
      clone.vm_id = 109;
      clone.node_name = "dd7a-pve-1";
      datastore_id = "rbd-tarook";
      nodes = let
        mkMasterNode = values: lib.foldl' lib.recursiveUpdate node_defaults [master_defaults values];
        mkWorkerNode = values: lib.foldl' lib.recursiveUpdate node_defaults [worker-defaults values];

        node_defaults = {
          network_device = {
            bridge = "vmbr1000";
            firewall = true;
          };
        };
        master_defaults = {
          role = "master";
          cores = 2;
          memory = 4096;
          root_disk_size = 25;
        };
        worker-defaults = {
          role = "worker";
          cores = 4;
          memory = 8192;
          root_disk_size = 50;
        };
      in {
        master-0 = mkMasterNode {
          target_node = "dd7a-pve-1";
          ipv4_address = "192.168.106.54";
        };
        master-1 = mkMasterNode {
          target_node = "dd7a-pve-2";
          ipv4_address = "192.168.106.55";
        };
        master-2 = mkMasterNode {
          target_node = "dd7a-pve-3";
          ipv4_address = "192.168.106.56";
        };
        worker-0 = mkWorkerNode {
          target_node = "dd7a-pve-1";
          ipv4_address = "192.168.106.60";
        };
        worker-1 = mkWorkerNode {
          target_node = "dd7a-pve-2";
          ipv4_address = "192.168.106.61";
          network_device.firewall = false;
          cores = 1;
          memory = 1024;
          root_disk_size = 20;
        };
      };
    };
    kubernetes = {
      kubelet = {
        defaultOptions = {
          maxPods = 110;
        };
        workerOptions = {
          evictionSoft = {
            "memory.available" = "384Mi";
          };
          evictionSoftGracePeriod = {
            "memory.available" = "1m25s";
          };
          evictionHard = {
            "memory.available" = "256Mi";
            "nodefs.available" = "12%";
            "imagefs.available" = "15%";
            "nodefs.inodesFree" = "7%";
          };
        };
      };
      apiserver = {
        frontend_port = 8888;
        audit_logs.enabled = true;
      };
      controller_manager = {
        enable_signing_requests = true;
      };
      storage = {
        nodeplugin_toleration = true;
      };
      local_storage = {
        static = {
          enabled = true;
          storageclass_name = "local-storage-static";
        };
        dynamic = {
          enabled = true;
          storageclass_name = "local-storage-dynamic";
        };
      };
      network = {
        pod_subnet = "10.244.0.0/16";
        service_subnet = "10.96.0.0/12";
      };
    };
    k8s-service-layer = {
      cert-manager = {
        enabled = true;
      };
      ingress = {
        enabled = true;
      };
      vault = {
        enabled = false;
        ingress = false;
        enable_backups = false;
      };
    };
    testing = {
      force_reboot_nodes = true;
    };
    miscellaneous = {
      custom_chrony_configuration = true;
      custom_ntp_servers = [
        "0.de.pool.ntp.org"
        "1.de.pool.ntp.org"
        "2.de.pool.ntp.org"
        "3.de.pool.ntp.org"
      ];
    };
    vault = {
      cluster_name = "k8s.ci.yaook.cloud";
      policy_prefix = "yaook";
      path_prefix = "yaook";
      nodes_approle = "yaook/nodes";
    };
  };
}
