{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (yk8s-lib) mkInternalOption types;
in {
  options.yk8s.kubernetes.kubeadm = {
    upgradeConfigurations = lib.mkOption {
      description = ''
        Per node kubeadm UpgradeConfigurations

        Values are expected be adhere to the schema documented at
        https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-UpgradeConfiguration
      '';
      type = with types; attrsOf yk8s.formats.jsonValue;
    };
    upgradeConfigurationFiles = mkInternalOption {
      type = with types; attrsOf pathInStore;
      readOnly = true;
    };
  };
  config.yk8s.kubernetes.kubeadm = let
    mkUpgradeConfiguration = hostName: hostValues: {
      apiVersion = "kubeadm.k8s.io/v1beta4";
      kind = "UpgradeConfiguration";
      apply = {
        # `kubernetesVersion` will be set set via command line
        ignorePreflightErrors = [
          "CreateJob"
        ];
        # Do not renew certificates because we are rolling out our own chain
        certificateRenewal = false;
        patches.directory = cfg.kubeadm.patches_remote_dir;
      };
      node = {
        # Do not renew certificates because we are rolling out our own chain
        certificateRenewal = false;
        patches.directory = cfg.kubeadm.patches_remote_dir;
      };
    };
  in {
    upgradeConfigurations = lib.mapAttrs mkUpgradeConfiguration config.yk8s.infra.final_hosts.masters.hosts;
    upgradeConfigurationFiles = lib.mapAttrs (hostName: yk8s-lib.mkYaml "${hostName}-upgradeConfiguration.yaml") cfg.kubeadm.upgradeConfigurations;
  };
}
