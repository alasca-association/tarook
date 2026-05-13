{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in {
  yk8s = {
    # A reference for all available options can be found at
    # https://docs.tarook.cloud/devel/user/reference/options/index.html
    infra = {
      cluster_name = "devcluster";
      subnet_cidr = "192.168.67.0/24";
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
          network_device = {
            bridge = "vmbr1000";
          };
          ipv4_address = "192.168.106.54";
        };
        worker-0 = mkWorkerNode {
          target_node = "dd7a-pve-2";
          ipv4_address = "192.168.106.60";
        };
        worker-1 = mkWorkerNode {
          target_node = "dd7a-pve-3";
          ipv4_address = "192.168.106.61";
          cores = 8;
          memory = 4096;
          root_disk_size = 90;
        };
      };
    };
    kubernetes = {
      # NOTE: The following comment is needed for Tarook's dependency
      #       management which keeps the Kubernetes version up-to-date with
      #       renovate-bot. Safe to remove.
      # renovate: datasource=github-releases packageName=kubernetes/kubernetes
      version = "1.33.11";
    };
  };
}
