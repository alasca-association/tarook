{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (yk8s-lib) mkInternalOption types;

  inherit (config.yk8s.infra) ipv4_enabled ipv6_enabled;
  mkNodeRegistration = hostName: hostValues: {
    name = hostName;
    kubeletExtraArgs =
      [
        {
          name = "node-ip";
          value = lib.concatStringsSep "," (
            (lib.optional ipv4_enabled hostValues.local_ipv4_address)
            ++ (lib.optional ipv6_enabled hostValues.local_ipv6_address)
          );
        }
      ]
      ++ lib.optional config.yk8s.openstack.enabled {
        name = "cloud-provider";
        value = "external";
      };
  };
  mkLocalAPIEndpoint = hostValues: {
    advertiseAddress =
      if ipv4_enabled
      then hostValues.local_ipv4_address
      else hostValues.local_ipv6_address;
    bindPort = 6443;
  };
in {
  options.yk8s.kubernetes.kubeadm = {
    initConfigurations = lib.mkOption {
      type = with types; attrsOf yk8s.formats.jsonValue;
    };
    joinConfigurations = lib.mkOption {
      type = with types; attrsOf yk8s.formats.jsonValue;
    };
    initConfigurationFiles = mkInternalOption {
      type = with types; attrsOf pathInStore;
      default = lib.mapAttrs (hostName: yk8s-lib.mkYaml "${hostName}-initConfiguration.yaml") cfg.kubeadm.initConfigurations;
    };
    joinConfigurationFiles = mkInternalOption {
      type = with types; attrsOf pathInStore;
      default = lib.mapAttrs (hostName: yk8s-lib.mkYaml "${hostName}-joinConfiguration.yaml") cfg.kubeadm.joinConfigurations;
    };
    initConfigurationBundles = mkInternalOption {
      type = with types; attrsOf pathInStore;
      default =
        lib.mapAttrs (
          hostName: initConfiguration:
            yk8s-lib.mkYamlBundle "${hostName}-initConfigurationBundle.yaml" ([
                initConfiguration
                cfg.kubeadm.clusterConfiguration
                ({
                    apiVersion = "kubelet.config.k8s.io/v1beta1";
                    kind = "KubeletConfiguration";
                  }
                  // cfg.kubelet.defaultOptions)
              ]
              ++ lib.optional cfg.network.kube_proxy.enabled cfg.network.kube_proxy.kubeProxyConfiguration)
        )
        cfg.kubeadm.initConfigurations;
    };
  };
  config.yk8s.kubernetes.kubeadm = {
    initConfigurations = let
      mkInitConfiguration = hostName: hostValues: {
        apiVersion = "kubeadm.k8s.io/v1beta4";
        kind = "InitConfiguration";
        nodeRegistration = mkNodeRegistration hostName hostValues;
        localAPIEndpoint = mkLocalAPIEndpoint hostValues;
        patches.directory = cfg.kubeadm.patches_remote_dir;
      };
    in
      lib.mapAttrs mkInitConfiguration config.yk8s.infra.final_hosts.masters.hosts;
    joinConfigurations = let
      mkJoinConfiguration = hostName: hostValues: {
        apiVersion = "kubeadm.k8s.io/v1beta4";
        kind = "JoinConfiguration";
        nodeRegistration =
          (mkNodeRegistration hostName hostValues)
          // {
            ignorePreflightErrors = [
              "FileAvailable--etc-kubernetes-kubelet.conf"
            ];
          };
        discovery = {
          file.kubeConfigPath = "/etc/kubernetes/kubelet.conf";
          timeout = "5m0s";
        };
        controlPlane.localAPIEndpoint = mkLocalAPIEndpoint hostValues;
        patches.directory = cfg.kubeadm.patches_remote_dir;
      };
    in
      lib.mapAttrs mkJoinConfiguration config.yk8s.infra.final_hosts.k8s_nodes.hosts;
  };
}
