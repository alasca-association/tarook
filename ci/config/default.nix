{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in {
  # Some values need to be changed during CI runs, so we use an override file
  imports = [./overrides.nix];

  config.yk8s = {
    # A reference for all available options can be found at
    # https://yaook.gitlab.io/k8s/devel/user/reference/options/index.html
    infra = {
      cluster_name = "ci";
      ipv6_enabled = false;
      subnet_v6_cidr = "fd00::/120";
    };
    openstack = {
      azs = [
        "AZ1"
        "AZ2"
        "AZ3"
      ];
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
        flavor = "XS";
        image = "Debian 12 (bookworm)";
      };
      spread_gateways_across_azs = false;
      nodes = {
        master-0 = {
          role = "master";
        };
        master-1 = {
          role = "master";
          image = "Ubuntu 22.04 LTS x64";
          az = "AZ1";
        };
        master-2 = {
          role = "master";
        };
        worker-storage-0 = {
          role = "worker";
          flavor = "XL";
          image = "Ubuntu 22.04 LTS x64";
        };
        worker-cpu-0 = {
          role = "worker";
          flavor = "L";
          image = "Ubuntu 22.04 LTS x64";
        };
        worker-storage-1 = {
          role = "worker";
          flavor = "L";
          az = "AZ2";
        };
        worker-cpu-1 = {
          role = "worker";
          flavor = "L";
          az = "AZ3";
        };
        worker-storage-2 = {
          role = "worker";
          flavor = "XL";
        };
        worker-gpu-0 = {
          role = "worker";
          flavor = "CH-8C:32:100s-GN:1xTeslaT4";
        };
        worker-cpu-2 = {
          role = "worker";
          flavor = "M";
        };
      };
    };
    load-balancing = {
      deprecated_nodeport_lb_test_port = 30060;
      lb_ports = [
        30060
      ];
    };
    wireguard = {
      endpoints = [
        {
          id = 0;
          enabled = true;
          ip_cidr = "172.30.153.0/24";
          ip_gw = "172.30.153.1/24";
          ipv6_cidr = "fd01::/120";
          ipv6_gw = "fd01::1/120";
          port = 7777;
        }
        {
          id = 1;
          enabled = true;
          ip_cidr = "172.30.152.0/24";
          ip_gw = "172.30.152.1/24";
          port = 7778;
        }
      ];
      peers = [
        {
          pub_key = "MQL6dL0DSOnXTLrScCseY7Fs8S5Hb4yHc6SZ+/ucNx0=";
          ip = "172.30.153.14/32";
          ipv6 = "fd01::14/128";
          ident = "gitlab-ci-runner";
        }
      ];
    };
    ch-k8s-lbaas = {
      enabled = true;
      shared_secret = "IYeOlEFO1h3uc9x1bdw9thNNgmn1gm8dmzos3f04PLmFjt3d";
      agent_port = 15203;
    };
    kubernetes = {
      is_gpu_cluster = true;
      virtualize_gpu = false;
      kubelet = {
        evictionsoft_memory_period = "1m25s";
        evictionhard_nodefs_available = "12%";
        evictionhard_nodefs_inodesfree = "7%";
      };
      apiserver = {
        frontend_port = 8888;
      };
      controller_manager = {
        enable_signing_requests = true;
      };
      storage = {
        rook_enabled = true;
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
      monitoring = {
        enabled = true;
      };
      network = {
        pod_subnet = "10.244.0.0/16";
        service_subnet = "10.96.0.0/12";
      };
    };
    k8s-service-layer = {
      rook = {
        namespace = "rook-ceph";
        cluster_name = "rook-ceph";
        skip_upgrade_checks = true;
        nodeplugin_toleration = true;
        nmons = 3;
        nmgrs = 2;
        nosds = 3;
        osd_volume_size = "90Gi";
        encrypt_osds = true;
        toolbox = true;
        ceph_fs = true;
        mon_volume = true;
        mon_volume_storage_class = "local-storage-static";
        csi_plugins = true;
        use_host_networking = true;
        dashboard = true;
        mds_memory_limit = "4Gi";
        mds_cpu_request = "1";
        mon_cpu_limit = "500m";
        mon_cpu_request = "100m";
        mon_memory_limit = "1Gi";
        mon_memory_request = "500Mi";
        operator_cpu_limit = "500m";
        operator_cpu_request = "100m";
        scheduling_key = "${cfg.node-scheduling.scheduling_key_prefix}/storage";
        mgr_scheduling_key = "${cfg.node-scheduling.scheduling_key_prefix}/rook-mgr";
        pools = [
          {
            name = "data";
            create_storage_class = true;
            replicated = 1;
          }
          {
            name = "test-create-storage-class-false";
            create_storage_class = false;
            replicated = 1;
          }
          {
            name = "test-create-storage-class-undefined";
            replicated = 1;
          }
        ];
      };
      prometheus = {
        use_thanos = true;
        use_grafana = true;
        grafana_persistent_storage_class = "csi-sc-cinderplugin";
        prometheus_persistent_storage_class = "csi-sc-cinderplugin";
        thanos_objectstorage_container_name = "ci-monitoring-thanos-data";
        scheduling_key = "${cfg.node-scheduling.scheduling_key_prefix}/monitoring";
        grafana_memory_limit = "768Mi";
        grafana_memory_request = "768Mi";
        grafana_cpu_limit = "600m";
        grafana_cpu_request = "200m";
        thanos_store_in_memory_max_size = "1GB";
        internet_probe = true;
        internet_probe_targets = [
          {
            name = "yaook";
            url = "https://yaook.cloud/";
            interval = "60s";
            scrapeTimeout = "60s";
          }
          {
            name = "quad-9";
            url = "9.9.9.9";
            module = "icmp";
          }
        ];
        common_labels = {
          managed-by = "yaook-k8s";
        };
      };
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
      fluxcd = {
        enabled = true;
      };
    };
    testing = {
      force_reboot_nodes = true;
    };
    node-scheduling = {
      scheduling_key_prefix = "scheduling.mk8s.cloudandheat.com";
      labels = {
        ci-worker-storage-0 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true"
        ];
        ci-worker-storage-1 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true"
        ];
        ci-worker-storage-2 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true"
        ];
        ci-worker-cpu-0 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/monitoring=true"
          "${cfg.node-scheduling.scheduling_key_prefix}/rook-mgr=true"
        ];
        ci-worker-cpu-1 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/monitoring=true"
          "${cfg.node-scheduling.scheduling_key_prefix}/rook-mgr=true"
        ];
      };
      taints = {
        ci-worker-cpu-0 = [
        ];
        ci-worker-storage-0 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"
        ];
        ci-worker-storage-1 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"
        ];
        ci-worker-storage-2 = [
          "${cfg.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"
        ];
      };
    };
    ipsec = {
      enabled = true;
      test_enabled = true;
      proposals = [
        "aes256-sha256-modp2048"
      ];
      peer_networks = [
        "172.20.150.0/24"
      ];
      remote_addrs = [
        "185.128.117.230"
      ];
      remote_name = "185.128.117.230";
      remote_private_addrs = "172.20.150.154";
    };
    miscellaneous = {
      openstack_cinder_volume_type = "three_times_replicated-sitewide";
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
      # NOTE: Using non-default randomized values to trigger (hard-coding) errors
      policy_prefix = "yaook-ci-r1XeB-policy";
      path_prefix = "yaook-ci-r1XeB";
      nodes_approle = "yaook-ci-r1XeB-approle/nodes";
    };
  };
}
