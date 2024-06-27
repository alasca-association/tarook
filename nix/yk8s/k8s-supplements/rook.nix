{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.rook;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule mkRenamedResourceOptionModules mkMultiResourceOptionsModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection logIf mkGroupVarsFile mkMultiResourceOptions;
  inherit (yk8s-lib.types) k8sSize k8sCpus;
in {
  imports =
    [
      (mkRemovedOptionModule "k8s-service-layer.rook" "use_helm" "")
      (mkRemovedOptionModule "k8s-service-layer.rook" "on_openstack" "Set on_openstack=False in your hosts file instead.")
      (mkMultiResourceOptionsModule "k8s-service-layer.rook" {
        description = ''
          Requests and limits for rook/ceph

          The default values are the *absolute minimum* values required by rook. Going
          below these numbers will make rook refuse to even create the pods. See also:
          https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings
        '';
        resources = {
          mon.cpu.request = "100m";
          mon.memory.limit = "1Gi";

          osd.cpu.request = null;
          osd.memory.limit = "2Gi";

          mgr.cpu.request = "100m";
          mgr.memory.limit = "512Mi";

          mds.cpu.request = null;
          mds.memory.limit = "4Gi";

          operator.cpu.request = null;
          operator.memory.limit = "512Mi";
        };
      })
    ]
    ++ (mkRenamedResourceOptionModules "k8s-service-layer.rook" ["mon" "osd" "mgr" "mds" "operator"]);

  options.yk8s.k8s-service-layer.rook = mkTopSection {
    _docs.preface = ''
      The used rook setup is explained in more detail
      :doc:`here </user/explanation/services/rook-storage>`.

      .. note::

        To enable rook in a cluster on top of OpenStack, you need
        to set both ``k8s-service-layer.rook.nosds`` and
        ``k8s-service-layer.rook.osd_volume_size``, as well as enable
        ``kubernetes.storage.rook_enabled`` and either
        ``kubernetes.local_storage.dynamic.enabled`` or
        ``kubernetes.local_storage.static.enabled`` local
        storage (or both) (see :ref:`storage configuration <configuration-options.yk8s.kubernetes.storage>`).
    '';

    mon_allow_multiple_per_node = mkOption {
      type = types.bool;
      default = false;
    };

    mgr_use_pg_autoscaler = mkOption {
      type = types.bool;
      default = true;
    };

    osd_anti_affinity = mkOption {
      type = types.bool;
      default = true;
    };

    osd_autodestroy_safe = mkOption {
      type = types.bool;
      default = true;
    };

    helm_release_name_operator = mkOption {
      type = types.nonEmptyStr;
      default = "rook-ceph";
    };

    helm_release_name_cluster = mkOption {
      type = types.nonEmptyStr;
      default = "rook-ceph-cluster";
    };

    # If kubernetes.storage.rook_enabled is enabled, rook will be installed.
    namespace = mkOption {
      description = ''
        Namespace to deploy the rook in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.nonEmptyStr;
      default = "rook-ceph";
    };

    cluster_name = mkOption {
      type = types.nonEmptyStr;
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
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    version = mkOption {
      description = ''
        Version of rook to deploy
      '';
      type = types.strMatching "v1\\.[0-9]+\\.[0-9]+";
      default = "v1.14.9";
    };

    dashboard = mkEnableOption ''
      the ceph dashboard for viewing cluster status
    '';

    nodeplugin_toleration = mkOption {
      type = types.bool;
      default = true;
    };

    mon_volume = mkOption {
      type = types.bool;
      default = true;
    };

    mon_volume_size = mkOption {
      type = k8sSize;
      default = "10Gi";
    };

    mon_volume_storage_class = mkOption {
      description = ''
        Storage class name to be used by the ceph mons. SHOULD be compliant with one
        storage class you have configured in the kubernetes.local_storage section (or
        you should know what your are doing). Note that this is not the storage class
        name that rook will provide.
      '';
      type = types.nonEmptyStr;
      default = config.yk8s.kubernetes.local_storage.dynamic.storageclass_name;
      defaultText = "\${kubernetes.local_storage.dynamic.storageclass_name}";
    };

    use_host_networking = mkEnableOption "usage of the host network.";

    skip_upgrade_checks = mkOption {
      description = ''
        If OSDs are not replicated, the rook-ceph-operator will reject
        to perform upgrades, because OSDs will become unavailable.
        Set to True so rook will update even if OSDs would become unavailable.

        If set to true Rook won’t perform any upgrade checks on Ceph daemons
        during an upgrade. Use this at YOUR OWN RISK, only if you know what
        you’re doing.
        https://rook.github.io/docs/rook/v1.3/ceph-cluster-crd.html#cluster-settings
      '';
      type = types.bool;
      default = false;
    };

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
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage";
    };

    mon_scheduling_key = mkOption {
      description = ''
        Additionally it is possible to schedule mons and mgrs pods specifically.
        NOTE: Rook does not merge scheduling rules set in 'all' and the ones in 'mon' and 'mgr',
        but will use the most specific one for scheduling.
      '';
      type = with types; nullOr nonEmptyStr;
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
      type = with types; nullOr nonEmptyStr;
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
      default = 2;
      example = 1;
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
      type = types.nonEmptyStr;
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

    ceph_fs = mkEnableOption "the CephFS shared filesystem";

    ceph_fs_name = mkOption {
      type = types.nonEmptyStr;
      default = "ceph-fs";
    };

    ceph_fs_replicated = mkOption {
      type = types.ints.positive;
      default = 1;
    };

    ceph_fs_preserve_pools_on_delete = mkEnableOption "preservation of pools on delete";

    encrypt_osds = mkEnableOption "encryption of OSDs";

    pools = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.nonEmptyStr;
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
            type = types.nonEmptyStr;
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
            type = types.nonEmptyStr;
            default = "hdd";
          };
        };
      });
      default = [{name = "data";}];
    };

    use_all_available_devices = mkOption {
      description = ''
        See :doc:`/user/guide/rook/custom-storage`
      '';
      type = types.bool;
      default = true;
    };
    use_all_available_nodes = mkOption {
      description = ''
        See :doc:`/user/guide/rook/custom-storage`
      '';
      type = types.bool;
      default = true;
    };

    nodes = mkOption {
      description = ''
        You do also have the option to manually define the nodes to be used,
        their configuration and devices of the configured nodes as well as
        device-specific configurations. For these configurations to take effect
        one must set :ref:`configuration-options.yk8s.k8s-service-layer.rook.use_all_available_devices` and
        :ref:`configuration-options.yk8s.k8s-service-layer.rook.use_all_available_nodes` to ``false``.

        See :doc:`/user/guide/rook/custom-storage`
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
            type = types.nonEmptyStr;
          };
          config = mkOption {
            type = types.attrs;
            default = {};
          };
          devices = mkOption {
            default = [];
            type = with types;
              listOf (submodule {
                options = {
                  name = mkOption {
                    type = types.nonEmptyStr;
                  };
                  config = mkOption {
                    type = types.attrs;
                    default = {};
                  };
                };
              });
          };
        };
      });
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "rook_";
      inventory_path = "all/rook.yaml";
    })
  ];
}
