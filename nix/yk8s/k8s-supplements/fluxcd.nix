{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.fluxcd;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  imports = [
    (mkRemovedOptionModule "k8s-service-layer.fluxcd" "legacy" "Support for the legacy FluxCD installation has been dropped.\nYou must switch to an older release and migrate if you have not yet.")
  ];
  options.yk8s.k8s-service-layer.fluxcd = mkTopSection {
    _docs.preface = ''
      More details about our FluxCD2 implementation can be found
      :doc:`here </user/explanation/services/fluxcd>`.

      The following configuration options are available:
    '';

    enabled = mkEnableOption "Flux management";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall fluxcd2. IF SET TO
        FALSE, FLUXCD2 WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.
      '';
      type = types.bool;
      default = true;
    };
    helm_repo_url = mkOption {
      type = types.nonEmptyStr;
      default = "https://fluxcd-community.github.io/helm-charts";
    };
    version = mkOption {
      description = ''
        Helm chart version of FluxCD to be deployed.
      '';
      type = types.nonEmptyStr;
      # renovate: datasource=helm depName=flux2 registryUrl=https://fluxcd-community.github.io/helm-charts
      default = "2.9.2";
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
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "fluxcd_";
      inventory_path = "all/fluxcd.yaml";
    })
  ];
}
