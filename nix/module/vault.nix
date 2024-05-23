{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkInternalOption;
in {
  options.yk8s.vault = {
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
    _ansible_prefix = mkInternalOption {
      type = types.str;
      default = "vault_";
    };
    _inventory_path = mkInternalOption {
      type = types.str;
      default = "all/vault-backend.yaml";
    };
  };
}
