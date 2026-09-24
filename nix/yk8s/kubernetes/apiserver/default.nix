{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkInternalOption mkYaml types;
  inherit
    (yk8s-lib.transform)
    filterNull
    ;

  auditLogDirname = "/var/log/kubernetes/audit";
  auditLogFilename = "audit.log";
in {
  imports = [
    (mkRemovedOptionModule ["kubernetes" "apiserver" "audit_logs" "custom_policy"] "Use config.yk8s.kubernetes.apiserver.audit_logs.policy instead")
  ];
  options.yk8s.kubernetes.apiserver = {
    frontend_port = mkOption {
      type = types.port;
      default = 8888;
    };
    memory_limit = mkOption {
      description = ''
        Memory resources limit for the kube-apiserver.
        See `Requests and Limits <https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits>`_
        and `kube-apiserver <https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver>`_.

        If set, a respective patch file will be generated for
        :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kube-apiserver`.
      '';
      type = with types; nullOr yk8s.k8s.quantity;
      default = null;
      example = "1Gi";
    };
    event_ttl = mkOption {
      description = ''
        Event TTL for the kube-apiserver.
        See ``--event-ttl`` in `kube-apiserver options <https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/#options>`_.

        A respective patch file will be generated for
        :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kube-apiserver`.
      '';
      type = with types; yk8s.k8s.durationStr;
      default = "1h0m0s";
      example = "24h0m0s";
    };
    audit_logs = {
      enabled = mkEnableOption ''
        audit logs for the kube-apiserver.

        If enabled, a policy file is mounted to the kube-apiserver.
        The policy file can be adjusted via
        :ref:`configuration-options.yk8s.kubernetes.apiserver.audit_logs.policy`.
        Logs are written to ``${auditLogDirname}/${auditLogFilename}``.
        The ``audit-log-maxage`` and ``audit-log-maxbackup`` settings are
        currently hardcoded to ``1``'';
      max_size = mkOption {
        description = ''
          Maximum size of apiserver audit log files in megabytes before it gets rotated
        '';
        type = types.ints.unsigned;
        default = 50;
      };
      policy = let
        defaultsFile = ./audit-policy-defaults.nix;
      in
        mkOption {
          description = ''
            The audit policy for the kube-apiserver.
            Checkout the
            `Kubernetes Auditing Documentation <https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/#audit-policy>`_
            for further information on how to configure.

            You may use ``audit_logs.policy = yk8s-lib.importYAML ./path/to/policy.yaml;`` to import
            an existing policy manifest. Note that the YAML file has to be added to the git repository
            in order to be evaluated by Nix.

            Alternatively, if you prefer to specify the policy in Nix directly, you may use
            https://github.com/cloudandheat/json2nix to convert existing policies to Nix.

            Note that this option is not type checked by Nix, so make sure that it it's a valid audit policy.
          '';

          example = lib.options.literalExpression ''
            yk8s-lib.importYAML ./path/to/policy.yaml # Note that the file has to be added to the git repository to be evaluated by Nix
          '';
          type = types.submodule {
            freeformType = types.yk8s.formats.jsonValue;
          };
          default = import defaultsFile;

          # to include the comments in the docs
          defaultText = lib.options.literalExpression (builtins.readFile defaultsFile);
        };
      policy_file = mkInternalOption {
        readOnly = true;
        type = types.pathInStore;
        default = toString (mkYaml "audit-policy.yaml" (filterNull cfg.apiserver.audit_logs.policy));
      };
      policy_remote_file = mkInternalOption {
        readOnly = true;
        type = types.path;
        default = "/etc/kubernetes/audit-policy.yaml";
      };
    };
  };
  config.yk8s.kubernetes.kubeadm = {
    clusterConfiguration.apiServer = {
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
            value = cfg.apiserver.audit_logs.policy_remote_file;
          }
          {
            name = "audit-log-path";
            value = "${auditLogDirname}/${auditLogFilename}";
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
          hostPath = cfg.apiserver.audit_logs.policy_remote_file;
          mountPath = cfg.apiserver.audit_logs.policy_remote_file;
          readOnly = true;
          pathType = "File";
        }
        {
          name = "audit-log";
          hostPath = auditLogDirname;
          mountPath = auditLogDirname;
          pathType = "DirectoryOrCreate";
        }
      ];
    };
    patches.kube-apiserver =
      []
      # If config.yk8s.kubernetes.apiserver.memory_limit is set,
      # add a patch file for it
      ++ lib.optional (cfg.apiserver.memory_limit != null)
      {
        patchtype = "json";
        patch = [
          {
            op = "add";
            path = "/spec/containers/0/resources/limits";
            value.memory = "${cfg.apiserver.memory_limit}";
          }
        ];
      }
      # Create a patch file for config.yk8s.kubernetes.apiserver.event_ttl
      ++ [
        {
          patchtype = "json";
          patch = [
            {
              op = "add";
              path = "/spec/containers/0/command/-";
              value = "--event-ttl=${cfg.apiserver.event_ttl}";
            }
          ];
        }
      ];
  };
}
