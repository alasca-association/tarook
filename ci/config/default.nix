{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
  os_region_name = builtins.getEnv "OS_REGION_NAME";
  selectByRegion = builtins.getAttr os_region_name;

  scheduling_key_prefix = "scheduling.mk8s.cloudandheat.com";
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
    openstack = let
      ubuntu24 = selectByRegion {
        f1d = "Ubuntu 24.04";
        f1a = "Ubuntu 24.04 LTS x64";
      };
      ubuntu22 = selectByRegion {
        f1d = "Ubuntu 22.04";
        f1a = "Ubuntu 22.04 LTS x64";
      };
      debian = selectByRegion {
        f1d = "Debian 12";
        f1a = "Debian 12 (bookworm)";
      };
    in {
      azs = [
        "AZ1"
        "AZ2"
        "AZ3"
      ];
      public_network = selectByRegion {
        f1d = "public";
        f1a = "shared-public-IPv4";
      };
      master_defaults = {
        flavor = selectByRegion {
          f1d = "SCS-2T-4-25s";
          f1a = "M";
        };
        image = ubuntu24;
      };
      worker_defaults = {
        flavor = selectByRegion {
          f1d = "SCS-2T-4-25s";
          f1a = "M";
        };
        image = ubuntu24;
      };
      gateway_defaults = {
        flavor = selectByRegion {
          f1d = "SCS-1T-1-15s";
          f1a = "XS";
        };
        image = debian;
      };
      spread_gateways_across_azs = false;
      nodes = {
        master-0 = {
          role = "master";
        };
        master-1 = {
          role = "master";
          image = ubuntu22;
          az = "AZ1";
        };
        master-2 = {
          role = "master";
        };
        worker-storage-0 = {
          role = "worker";
          flavor = selectByRegion {
            f1d = "SCS-8T-16-100s";
            f1a = "XL";
          };
          image = ubuntu22;
        };
        worker-cpu-0 = {
          role = "worker";
          flavor = selectByRegion {
            f1d = "SCS-4T-8-50s";
            f1a = "L";
          };
          image = ubuntu22;
        };
        worker-storage-1 = {
          role = "worker";
          flavor = selectByRegion {
            f1d = "SCS-4T-8-50s";
            f1a = "L";
          };
          az = "AZ2";
        };
        worker-cpu-1 = {
          role = "worker";
          flavor = selectByRegion {
            f1d = "SCS-4T-8-50s";
            f1a = "L";
          };
          az = "AZ3";
        };
        worker-storage-2 = {
          role = "worker";
          flavor = selectByRegion {
            f1d = "SCS-8T-16-100s";
            f1a = "XL";
          };
        };
        worker-gpu-0 = {
          role = "worker";
          flavor = "CH-8C:32:100s-GN:1xTeslaT4";
        };
        worker-cpu-2 = {
          role = "worker";
        };
      };
      cinder_volume_type = selectByRegion {
        f1d = "f1c-hdd";
        f1a = "three_times_replicated-sitewide";
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
          ip = "172.30.153.14";
          ipv6 = "fd01::14";
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
        enabled = true;
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
        mds_resources = {
          limits.memory = "4Gi";
          requests.cpu = "1";
        };
        mon_resources = {
          limits.memory = "1Gi";
          requests.cpu = "100m";
        };
        mgr_resources = {
          limits.memory = "768Mi";
        };
        operator_resources.requests.cpu = "100m";
        scheduling_key = "${scheduling_key_prefix}/storage";
        mgr_scheduling_key = "${scheduling_key_prefix}/rook-mgr";
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
        thanos_objectstorage_config_file = "thanos.yaml";
        manage_thanos_bucket = false;
        scheduling_key = "${scheduling_key_prefix}/monitoring";
        grafana_resources = {
          limits.memory = "768Mi";
          requests.cpu = "200m";
        };
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
      labels = {
        ci-worker-storage-0 = [
          "${scheduling_key_prefix}/storage=true"
        ];
        ci-worker-storage-1 = [
          "${scheduling_key_prefix}/storage=true"
        ];
        ci-worker-storage-2 = [
          "${scheduling_key_prefix}/storage=true"
        ];
        ci-worker-cpu-0 = [
          "${scheduling_key_prefix}/monitoring=true"
          "${scheduling_key_prefix}/rook-mgr=true"
        ];
        ci-worker-cpu-1 = [
          "${scheduling_key_prefix}/monitoring=true"
          "${scheduling_key_prefix}/rook-mgr=true"
        ];
      };
      taints = {
        ci-worker-cpu-0 = [
        ];
        ci-worker-storage-0 = [
          "${scheduling_key_prefix}/storage=true:NoSchedule"
        ];
        ci-worker-storage-1 = [
          "${scheduling_key_prefix}/storage=true:NoSchedule"
        ];
        ci-worker-storage-2 = [
          "${scheduling_key_prefix}/storage=true:NoSchedule"
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
      remote_private_addrs = ["172.20.150.154"];
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
