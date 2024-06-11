{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.fluxcd;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.k8s-service-layer.fluxcd = mkTopSection {
    enabled = mkEnableOption "Enable Flux management";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall fluxcd2. IF SET TO
        FALSE, FLUXCD2 WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.
      '';
      type = types.bool;
      default = true;
    };
    version = mkOption {
      description = ''
        Helm chart version of fluxcd to be deployed.
      '';
      type = types.str;
      default = "2.9.2";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the flux-system in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.str;
      default = "k8s-svc-flux-system";
    };
  };
  config.yk8s.k8s-service-layer.fluxcd = {
    _ansible_prefix = "fluxcd_";
    _inventory_path = "all/fluxcd.yaml";
  };
}
