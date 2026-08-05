{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (yk8s-lib) types;
in {
  options.yk8s.kubernetes.kubeadm = {
    clusterConfiguration = lib.mkOption {
      type = types.yk8s.formats.jsonValue;
    };
  };
  config.yk8s.kubernetes.kubeadm.clusterConfiguration = let
    inherit
      (config.yk8s.infra)
      ipv4_enabled
      ipv6_enabled
      networking_fixed_ip
      networking_fixed_ip_v6
      ;
  in {
    apiVersion = "kubeadm.k8s.io/v1beta4";
    kind = "ClusterConfiguration";
    kubernetesVersion = "v${cfg.version}";
    controlPlaneEndpoint = "${
      if ipv4_enabled
      then networking_fixed_ip
      else "[${networking_fixed_ip_v6}]"
    }:${toString cfg.apiserver.frontend_port}";
    networking = {
      podSubnet = lib.concatStringsSep "," (
        (lib.optional ipv4_enabled cfg.network.pod_subnet)
        ++ (lib.optional ipv6_enabled cfg.network.pod_subnet_v6)
      );
      serviceSubnet = lib.concatStringsSep "," (
        (lib.optional ipv4_enabled cfg.network.service_subnet)
        ++ (lib.optional ipv6_enabled cfg.network.service_subnet_v6)
      );
    };
    proxy.disabled = !cfg.network.kube_proxy.enabled;
    apiServer = let
      auditPolicyPath = "/etc/kubernetes/audit-policy.yaml";
      auditLogsDir = "/var/log/kubernetes/audit";
    in {
      extraArgs =
        [
          {
            name = "service-account-issuer";
            value = "https://kubernetes.default.svc";
          }
          {
            name = "service-account-signing-key-file";
            value = "/etc/kubernetes/pki/sa.key";
          }
          {
            name = "enable-admission-plugins";
            value = "NodeRestriction";
          }
        ]
        ++ lib.optionals cfg.apiserver.audit_logs.enabled [
          {
            name = "audit-policy-file";
            value = auditPolicyPath;
          }
          {
            name = "audit-log-path";
            value = "${auditLogsDir}/audit.log";
          }
          {
            name = "audit-log-maxage";
            value = "1";
          }
          {
            name = "audit-log-maxsize";
            value = toString cfg.apiserver.audit_logs.max_size;
          }
          {
            name = "audit-log-maxbackup";
            value = "1";
          }
        ];
      extraVolumes = lib.optionals cfg.apiserver.audit_logs.enabled [
        {
          name = "audit-policy";
          hostPath = auditPolicyPath;
          mountPath = auditPolicyPath;
          readOnly = true;
          pathType = "File";
        }
        {
          name = "audit-log";
          hostPath = auditLogsDir;
          mountPath = auditLogsDir;
          pathType = "DirectoryOrCreate";
        }
      ];
    };
    etcd.local.extraArgs = lib.optional (ipv4_enabled && ipv6_enabled) {
      name = "listen-metrics-urls";
      value = "http://127.0.0.1:2381,http://[::1]:2381";
    };
    controllerManager.extraArgs =
      [
        {
          name = "bind-address";
          value =
            if ipv4_enabled
            then "0.0.0.0"
            else "::";
        }
        {
          name = "large-cluster-size-threshold";
          value = toString cfg.controller_manager.large_cluster_size_threshold;
        }
      ]
      ++ lib.optional ipv6_enabled {
        # The size for the pod subnets of the nodes.
        # This value is not respected by calico.
        # The maximum allowed diff is 16 bits and the smallest allowed value is /112
        name = "node-cidr-mask-size-ipv6";
        value = let
          inherit (types.yk8s.networking._regexes.cidr) ipv6SuffixRE;
          inherit (types.yk8s.networking._regexes.rfc3513) ipv6AddressRE;
          subnet_suffix = lib.last (builtins.match "^${ipv6AddressRE}(${ipv6SuffixRE})$" config.yk8s.infra.subnet_v6_cidr);
          networkBits = lib.toInt (lib.removePrefix "/" subnet_suffix);
        in
          lib.min (networkBits + 16) 122;
      };
    scheduler.extraArgs = [
      {
        name = "bind-address";
        value =
          if ipv4_enabled
          then "0.0.0.0"
          else "::";
      }
    ];
  };
}
