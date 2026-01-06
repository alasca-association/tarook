{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
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
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "vault_";
      inventory_path = "all/vault-backend.yaml";
    })
  ];
}
