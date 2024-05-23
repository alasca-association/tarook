{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.kubelet;
  inherit (lib) mkOption mkEnableOption types;
in {
  options.yk8s.kubernetes.kubelet = {
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
