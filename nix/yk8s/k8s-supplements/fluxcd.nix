{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.fluxcd;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.k8s-service-layer.fluxcd = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.flux:

      Flux
      ^^^^

      More details about our FluxCD2 implementation can be found
      :doc:`here </user/explanation/services/fluxcd>`.

      The following configuration options are available:
    '';

    enabled = mkEnableOption "Flux management";
    legacy = mkEnableOption "usage of the legacy version of flux";
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
      default =
        if cfg.legacy
        then "v0.36.0"
        else "2.9.2";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the flux-system in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.nonEmptyStr;
      default = "k8s-svc-flux-system";
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the flux instance and its resources. Has no
        default.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "fluxcd_";
      inventory_path = "all/fluxcd.yaml";
    })
  ];
}
