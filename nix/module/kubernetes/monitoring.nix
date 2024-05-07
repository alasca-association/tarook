{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.global_monitoring;
  removed-lib = import ../lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRenamedOptionModuleWithNewSection;
  inherit (lib) mkOption mkEnableOption types;
in {
  imports = [
    (mkRenamedOptionModuleWithNewSection "kubernetes" "monitoring.alertmanager_config_secret" "k8s-service-layer.prometheus" "alertmanager_config_secret")
  ];
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
