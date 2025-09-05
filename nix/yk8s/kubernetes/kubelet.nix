{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.kubelet;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkSubSection types;
in {
  imports = [
    (mkRenamedOptionModule "kubernetes" "kubelet.pod_limit" "kubelet.pod_limit_worker")
  ];

  options.yk8s.kubernetes.kubelet = mkSubSection {
    _docs.order = 9;
    _docs.preface = ''
      The LCM supports the customization of certain variables of ``kubelet``
      for (meta-)worker nodes.

      .. note::

        Applying changes requires to enable
        :ref:`disruptive actions <environmental-variables.behavior-altering-variables>`.
    '';

    pod_limit_master = mkOption {
      description = ''
        Maximum number of Pods per master node
        Increasing this value may also decrease performance,
        as more Pods can be packed into a single node.
        Therefore it's especially helpful for nodes which have much resources.
      '';
      type = types.int;
      default = 110;
    };
    pod_limit_worker = mkOption {
      description = ''
        Maximum number of Pods per worker node
        Increasing this value may also decrease performance,
        as more Pods can be packed into a single node.
        Therefore it's especially helpful for nodes which have much resources.
      '';
      type = types.ints.unsigned;
      default = 110;
    };
    evictionsoft_memory_period = mkOption {
      description = ''
        Config for soft eviction values.
        Note: To change this value you have to release the Kraken
      '';
      type = types.yk8s.k8s.durationStr;
      default = "1m30s";
    };
    evictionhard_nodefs_available = mkOption {
      description = ''
        Config for hard eviction values.
        Note: To change this value you have to release the Kraken
      '';
      type = types.yk8s.k8s.threshold;
      default = "10%";
    };
    evictionhard_nodefs_inodesfree = mkOption {
      description = ''
        Config for hard eviction values.
        Note: To change this value you have to release the Kraken
      '';
      type = types.yk8s.k8s.threshold;
      default = "5%";
    };
  };
}
