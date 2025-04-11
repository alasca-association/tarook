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
      Prometheus-based monitoring.
      For prometheus-specific configurations take a look at the config options in
      :ref:`configuration-options.yk8s.k8s-service-layer.prometheus`.
    '';
  };
}
