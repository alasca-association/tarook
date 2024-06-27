{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.kubelet;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkSubSection;
in {
  options.yk8s.kubernetes.kubelet = mkSubSection {
    _docs.order = 9;
    _docs.preface = ''
      .. _cluster-configuration.kubelet-configuration:

      kubelet Configuration
      ^^^^^^^^^^^^^^^^^^^^^

      The LCM supports the customization of certain variables of ``kubelet``
      for (meta-)worker nodes.

      .. note::

        Applying changes requires to enable
        :ref:`disruptive actions <environmental-variables.behavior-altering-variables>`.
    '';

    pod_limit = mkOption {
      description = ''
        Maximum number of Pods per worker
        Increasing this value may also decrease performance,
        as more Pods can be packed into a single node.
      '';
      type = types.int;
      default = 110;
    };
    evictionsoft_memory_period = mkOption {
      description = ''
        Config for soft eviction values.
        Note: To change this value you have to release the Kraken
      '';
      default = "1m30s";
    };
    evictionhard_nodefs_available = mkOption {
      description = ''
        Config for hard eviction values.
        Note: To change this value you have to release the Kraken
      '';
      default = "10%";
    };
    evictionhard_nodefs_inodesfree = mkOption {
      description = ''
        Config for hard eviction values.
        Note: To change this value you have to release the Kraken
      '';
      default = "5%";
    };
  };
}
