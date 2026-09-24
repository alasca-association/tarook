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
    # TODO: Support Kubernetes worker nodes as well
    # TODO: Support omission
    upgradeConfigurations = lib.mkOption {
      description = ''
        Per node kubeadm UpgradeConfigurations

        Values are expected be adhere to the schema documented at
        https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-UpgradeConfiguration

        There must be an entry for each master node.

        .. attention::

           UpgradeConfigurations will only passed to
           ``kubeadm upgrade apply`` and  ``kubeadm upgrade node``
           on master nodes.
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
  config.yk8s._targets.ansible.assertions = [
    # Ensure that there is an upgradeConfiguration for each Kubernetes control plane node
    # since absence is not handled in Ansible yet
    (let
      masterNodesWithoutUpgradeConfig =
        lib.subtractLists
        (lib.attrNames config.yk8s.infra.final_hosts.masters.hosts)
        (lib.attrNames cfg.kubeadm.upgradeConfigurations);
    in {
      assertion = (lib.length masterNodesWithoutUpgradeConfig) == 0;
      message = lib.concatStrings [
        "config.yk8s.kubernetes.kubeadm.upgradeConfigurations:"
        " no entry for one or more master nodes:"
        (lib.concatStringsSep ", " masterNodesWithoutUpgradeConfig)
      ];
    })
  ];
  config.yk8s._targets.ansible.warnings =
    []
    # Produce warning if upgradeConfiguration is not mapped to a Kubernetes control plane node
    # since that's not supported yet and will be ignored
    ++ (lib.foldl' (acc: e:
      acc
      ++ lib.optional
        (! lib.hasAttr e (config.yk8s.infra.final_hosts.masters.hosts or {}))
        (lib.concatStrings [
          "config.yk8s.kubernetes.kubeadm.upgradeConfigurations.${e}:"
          " will be ignored, because "
          (
            if (lib.hasAttr e (config.yk8s.infra.final_hosts.all.hosts or {}))
            then "${e} is not a master node"
            else "${e} does not exist in config.yk8s.infra.ansible_hosts"
          )
        ])
      ) [] (lib.attrNames cfg.kubeadm.upgradeConfigurations)
    );
}
