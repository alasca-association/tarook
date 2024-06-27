{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.vault = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.vault:

      Vault Configuration
      ^^^^^^^^^^^^^^^^^^^
    '';
    cluster_name = mkOption {
      description = ''
        Name of the cluster inside Vault. The secrets engines are searched for
        relative to $path_prefix/$cluster_name/.
        This name must be unique within a single vault instance and cannot be
        reasonably changed after a cluster has been spawned.
      '';
      type = types.str;
      default = "devcluster";
    };
    policy_prefix = mkOption {
      type = types.str;
      default = "yaook";
    };
    path_prefix = mkOption {
      type = types.str;
      default = "yaook";
    };
    nodes_approle = mkOption {
      type = types.str;
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
