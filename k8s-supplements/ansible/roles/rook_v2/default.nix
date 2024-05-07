{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.rook;
  removed-lib = import ../../../../nix/module/lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRenamedOptionModule mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection logIf mkGroupVarsFile;
  inherit (yk8s-lib.types) k8sSize k8sCpus;

  resource_notice = ''
    The default values are the *absolute minimum* values required by rook. Going
    below these numbers will make rook refuse to even create the pods. See also:
    https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings
  '';
in {
  imports = [
    (mkRemovedOptionModule "k8s-service-layer.rook" "use_helm" "")
  ];
  options.yk8s.k8s-service-layer.rook = mkTopSection {
    # If kubernetes.storage.rook_enabled is enabled, rook will be installed.
    namespace = mkOption {
      description = ''
        Namespace to deploy the rook in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.str;
      default = "rook-ceph";
    };

    cluster_name = mkOption {
      type = types.str;
      default = "rook-ceph";
    };

    custom_ceph_version = mkOption {
      description = ''
        Configure a custom Ceph version.
        If not defined, the one mapped to the rook version
        will be used. Be aware that you can't choose an
        arbitrary Ceph version, but should stick to the
        rook-ceph-compatibility-matrix.
      '';
      type = with types; nullOr str;
      default = null;
    };

    version = mkOption {
      description = ''
        Version of rook to deploy
      '';
      type = types.strMatching "v1\\.[2-8]\\.[0-9]+";
      default = "v1.7.11";
    };

    dashboard = mkEnableOption ''
      Enable the ceph dashboard for viewing cluster status
    '';

    nodeplugin_toleration = mkOption {
      type = types.bool;
      default = true;
    };

    mon_volume_storage_class = mkOption {
      description = ''
        Storage class name to be used by the ceph mons. SHOULD be compliant with one
        storage class you have configured in the kubernetes.local_storage section (or
        you should know what your are doing). Note that this is not the storage class
        name that rook will provide.
      '';
      type = types.str;
      default = config.yk8s.kubernetes.local_storage.dynamic.storageclass_name;
      defaultText = "\${kubernetes.local_storage.dynamic.storageclass_name}";
    };

    use_host_networking = mkEnableOption "Enables rook to use the host network.";

    skip_upgrade_checks = mkEnableOption ''
      If OSDs are not replicated, the rook-ceph-operator will reject
      to perform upgrades, because OSDs will become unavailable.
      Set to True so rook will update even if OSDs would become unavailable.

      If set to true Rook won’t perform any upgrade checks on Ceph daemons
      during an upgrade. Use this at YOUR OWN RISK, only if you know what
      you’re doing.
      https://rook.github.io/docs/rook/v1.3/ceph-cluster-crd.html#cluster-settings
    '';

    manage_pod_budgets = mkOption {
      description = ''
        If true, the rook operator will create and manage PodDisruptionBudgets
        for OSD, Mon, RGW, and MDS daemons.
      '';
      type = types.bool;
      default = true;
    };

    scheduling_key = mkOption {
      description = ''
        Scheduling keys control where services may run. A scheduling key corresponds
        to both a node label and to a taint. In order for a service to run on a node,
        it needs to have that label key.
        If no scheduling key is defined for a service, it will run on any untainted
        node.
      '';
      type = with types; nullOr str;
      default = null;
      example = "\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage";
    };

    mon_scheduling_key = mkOption {
      description = ''
        Additionally it is possible to schedule mons and mgrs pods specifically.
        NOTE: Rook does not merge scheduling rules set in 'all' and the ones in 'mon' and 'mgr',
        but will use the most specific one for scheduling.
      '';
      type = with types; nullOr str;
      default = null;
      example = "\${config.yk8s.node-scheduling.scheduling_key_prefix}/rook-mon";
    };

    mgr_scheduling_key = mkOption {
      description = ''
        Additionally it is possible to schedule mons and mgrs pods specifically.
        NOTE: Rook does not merge scheduling rules set in 'all' and the ones in 'mon' and 'mgr',
        but will use the most specific one for scheduling.
      '';
      # TODO: but we could do the merging here if we wanted to
      type = with types; nullOr str;
      default = null;
      example = "\${config.yk8s.node-scheduling.scheduling_key_prefix}/rook-mgr";
    };

    csi_plugins = mkOption {
      description = ''
        Set to false to disable CSI plugins, if they are not needed in the rook cluster.
        (For example if the ceph cluster is used for an OpenStack cluster)
      '';
      type = types.bool;
      default = true;
    };

    nmons = mkOption {
      description = ''
        Number of mons to run.
        Default is 3 and is the minimum to ensure high-availability!
        The number of mons has to be uneven.
      '';
      type = types.int;
      default = 3;
      apply = v: let
        isEven = num: (num - 2 * (num / 2)) == 0;
      in
        if (v < 3) || (isEven v)
        then throw "k8s-service-layer.rook.nmons must be an odd number >= 3"
        else v;
    };

    nmgrs = mkOption {
      description = ''
        Number of mgrs to run. Default is 1 and can be extended to 2
        and achieve high-availability.
        The count of mgrs is adjustable since rook v1.6 and does not work with older versions.
      '';
      type = types.ints.between 1 2;
      default = 1; # TODO conflicting values: role had 2
    };

    nosds = mkOption {
      description = ''
        Number of OSDs to run. This should be equal to the number of storage meta
        workers you use.
      '';
      type = types.ints.positive;
      default = 3;
    };

    osd_storage_class = mkOption {
      type = types.str;
      default = "csi-sc-cinderplugin";
    };

    osd_volume_size = mkOption {
      description = ''
        The size of the storage backing each OSD.
      '';
      type = k8sSize;
      default = "90Gi";
    };

    toolbox = mkOption {
      description = ''
        Enable the rook toolbox, which is a pod with ceph tools installed to
        introspect the cluster state.
      '';
      type = types.bool;
      default = true;
    };

    ceph_fs = mkEnableOption "Enable the CephFS shared filesystem";

    ceph_fs_name = mkOption {
      type = types.str;
      default = "ceph-fs";
    };

    ceph_fs_replicated = mkOption {
      type = types.ints.positive;
      default = 1;
    };

    ceph_fs_preserve_pools_on_delete = mkEnableOption "Preserve pools on delete";

    encrypt_osds = mkEnableOption "Enable the encryption of OSDs";

    # TODO: deprecate cpu limit (because it shouldnt be set)
    mon_cpu_limit = mkOption {
      description = ''
        CPU resources limit for the ceph mon
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };
    mon_cpu_request = mkOption {
      description = ''
        CPU resources request for the ceph mon
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = "100m";
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    mon_memory_request = mkOption {
      description = ''
        Memory resources request for the ceph mon.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = cfg.mon_memory_limit;
    };
    mon_memory_limit = mkOption {
      description = ''
        Memory resources limit for the ceph mon.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = "1Gi";
    };

    # TODO: deprecate cpu limit (because it shouldnt be set)
    osd_cpu_limit = mkOption {
      description = ''
        CPU resources limit for the OSD pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };
    osd_cpu_request = mkOption {
      description = ''
        CPU resources request for the OSD pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    osd_memory_request = mkOption {
      description = ''
        Memory resources request for the OSD pods.
        ${resource_notice}

        Note that these are chosen so that the OSD pods end up in the
        Guaranteed QoS class.
      '';
      type = types.nullOr k8sSize;
      default = cfg.osd_memory_limit;
    };
    osd_memory_limit = mkOption {
      description = ''
        Memory resources limit for the OSD pods.
        ${resource_notice}

        Note that these are chosen so that the OSD pods end up in the
        Guaranteed QoS class.
      '';
      type = types.nullOr k8sSize;
      default = "2Gi";
    };

    # TODO: deprecate cpu limit (because it shouldnt be set)
    mgr_cpu_limit = mkOption {
      description = ''
        CPU resources limit for the mgr pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };
    mgr_cpu_request = mkOption {
      description = ''
        CPU resources request for the mgr pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = "100m";
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    mgr_memory_request = mkOption {
      description = ''
        Memory resources request for the mgr pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = cfg.mgr_memory_limit;
    };
    mgr_memory_limit = mkOption {
      description = ''
        Memory resources limit for the mgr pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = "512Mi";
    };

    # TODO: deprecate cpu limit (because it shouldnt be set)
    mds_cpu_limit = mkOption {
      description = ''
        CPU resources limit for the mds pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };
    mds_cpu_request = mkOption {
      description = ''
        CPU resources request for the mds pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    mds_memory_request = mkOption {
      description = ''
        Memory resources request for the mds pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = cfg.mds_memory_limit;
    };
    mds_memory_limit = mkOption {
      description = ''
        Memory resources limit for the mds pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = "4Gi";
    };

    # TODO: deprecate cpu limit (because it shouldnt be set)
    operator_cpu_limit = mkOption {
      description = ''
        CPU resources limit for the operator pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };
    operator_cpu_request = mkOption {
      description = ''
        CPU resources request for the operator pods
        ${resource_notice}
      '';
      type = types.nullOr k8sCpus;
      default = null;
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    operator_memory_request = mkOption {
      description = ''
        Memory resources request for the operator pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = cfg.operator_memory_limit;
    };
    operator_memory_limit = mkOption {
      description = ''
        Memory resources limit for the operator pods.
        ${resource_notice}
      '';
      type = types.nullOr k8sSize;
      default = "512Mi";
    };

    pools = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "data";
          };
          create_storage_class = mkOption {
            type = types.bool;
            default = true;
          };
          replicated = mkOption {
            type = types.ints.positive;
            default = 1;
          };
          failure_domain = mkOption {
            type = types.str;
            default = "host";
          };
          erasure_coded = mkOption {
            default = null;
            type = types.nullOr (types.submodule {
              options = {
                data_chunks = mkOption {
                  type = types.ints.positive;
                  default = 2;
                };
                coding_chunks = mkOption {
                  type = types.ints.positive;
                  default = 1;
                };
              };
            });
          };
          device_class = mkOption {
            type = types.str;
            default = "hdd";
          };
        };
      });
      default = [{name = "data";}];
    };

    on_openstack = mkOption {
      description = ''
        If you’re not running on OpenStack you need to set this to false.
        See docs/user/guide/custom-storage.rst
      '';
      # currently this option is translated to rook_on_openstack which is never used
      type = types.bool;
      default = true;
    };
    use_all_available_devices = mkOption {
      description = ''
        See docs/user/guide/custom-storage.rst
      '';
      type = types.bool;
      default = true;
    };
    use_all_available_nodes = mkOption {
      description = ''
        See docs/user/guide/custom-storage.rst
      '';
      type = types.bool;
      default = true;
    };

    nodes = mkOption {
      description = ''
        You do also have the option to manually define the nodes to be used,
        their configuration and devices of the configured nodes as well as
        device-specific configurations. For these configurations to take effect
        one must set ``use_all_available_nodes`` and
        ``use_all_available_devices`` to ``false``.

        See docs/user/guide/custom-storage.rst
      '';
      default = [];
      apply = v:
        if v != [] && cfg.use_all_available_nodes
        then
          throw
          "[k8s-service-layer.rook] nodes definition is ignored because use_all_available_nodes is true"
        else v;
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          config = mkOption {
            type = types.attrs;
            default = {};
          };
          devices = mkOption {
            default = null;
            type = with types;
              nullOr (listOf (submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                  };
                  config = mkOption {
                    type = types.attrs;
                    default = {};
                  };
                };
              }));
          };
        };
      });
    };
  };
  # config.yk8s.on_openstack = cfg.on_openstack; # TODO: maybe use rename-option?
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "rook_";
      inventory_path = "all/rook.yaml";
    })
  ];
}
