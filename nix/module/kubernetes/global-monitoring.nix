{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.monitoring;
  inherit (lib) mkOption mkEnableOption types;
in {
  options.yk8s.kubernetes.monitoring = {
    enabled = mkEnableOption ''
      Enable Prometheus-based monitoring.
      For prometheus-specific configurations take a look at the
      k8s-service-layer.prometheus section.
    '';
  };
}
