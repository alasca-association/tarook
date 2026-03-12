{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types mkYamlAtPath;
in {
  options.yk8s.vault = mkTopSection {
    cluster_name = mkOption {
      description = ''
        Name of the cluster inside Vault. The secrets engines are searched for
        relative to $path_prefix/$cluster_name/.
        This name must be unique within a single vault instance and cannot be
        reasonably changed after a cluster has been spawned.
      '';
      type = with types; yk8s.vault.childNamespaceNameSegment;
      default = config.yk8s.infra.cluster_name;
      defaultText = "\${config.yk8s.infra.cluster_name}";
    };

    policy_prefix = mkOption {
      type = types.yk8s.vault.namespaceName;
      default = "yaook";
    };
    path_prefix = mkOption {
      type = types.yk8s.vault.namespaceName;
      default = "yaook";
    };
    nodes_approle = mkOption {
      type = types.yk8s.vault.namespaceName;
      default = "yaook/nodes";
    };
  };
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "vault_";
      inventory_path = "all/vault-backend.yaml";
    })
  ];
  config.yk8s._targets.vault.assertions = [];
  config.yk8s._targets.vault.warnings = [];
  config.yk8s._targets.vault = {
    inventory_subdir = "vault";
    inventory_packages = [
      (
        mkYamlAtPath "main.yaml" {
          wg_usage = config.yk8s.wireguard.enabled;
          k8s_controller_manager_enable_signing_requests = config.yk8s.kubernetes.controller_manager.enable_signing_requests;
          vault_cluster_name = cfg.cluster_name;
          thanos_enabled = config.yk8s.k8s-service-layer.prometheus.use_thanos;
          manage_thanos_bucket = config.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket;
          thanos_config_file = config.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file;
          vault_backup_s3_enabled = config.yk8s.k8s-service-layer.vault.enable_backups;
          vault_backup_s3_config_file = config.yk8s.k8s-service-layer.vault.s3_config_file;
        }
      )
    ];
  };
}
