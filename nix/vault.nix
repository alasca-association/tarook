{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.vault;
  inherit (lib) mkOption types;
  mkInternalOption = args:
    mkOption ({
        internal = true;
        visible = false;
      }
      // args);
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
      default = "${config.yk8s._ansible.inventory_base_path}/all/vault-backend.yaml";
    };
  };
}
