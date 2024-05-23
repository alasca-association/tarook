{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.global_monitoring;
  inherit (lib) mkOption mkEnableOption types;
in {
  options.yk8s.kubernetes.global_monitoring = {
    enabled = mkEnableOption ''
      Enable/Disable global monitoring
    '';
    nodeport = mkOption {
      type = types.port;
      default = 31911;
    };
    nodeport_name = mkOption {
      type = types.str;
      default = "ch-k8s-global-monitoring";
    };
  };
}
