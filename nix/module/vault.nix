{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.vault = mkTopSection {
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
  };
  config.yk8s.vault = {
    _ansible_prefix = "vault_";
    _inventory_path = "all/vault-backend.yaml";
  };
}
