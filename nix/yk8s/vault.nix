{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit
    (yk8s-lib.types)
    vaultChildNamespaceNameSegment
    vaultNamespaceName
    withLimitedLength
    ;
in {
  options.yk8s.vault = mkTopSection {
    cluster_name = mkOption {
      description = ''
        Name of the cluster inside Vault. The secrets engines are searched for
        relative to $path_prefix/$cluster_name/.
        This name must be unique within a single vault instance and cannot be
        reasonably changed after a cluster has been spawned.
      '';
      type = withLimitedLength {max = 32;} vaultChildNamespaceNameSegment; # see bug#721
      default = config.yk8s.infra.cluster_name;
      defaultText = "\${config.yk8s.infra.cluster_name}";
    };

    policy_prefix = mkOption {
      type = vaultNamespaceName;
      default = "yaook";
    };
    path_prefix = mkOption {
      type = vaultNamespaceName;
      default = "yaook";
    };
    nodes_approle = mkOption {
      type = vaultNamespaceName;
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
