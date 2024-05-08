{
  inputs,
  lib,
  self,
  flake-parts-lib,
  ...
}:
with lib; {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        options,
        pkgs,
        inputs',
        system,
        ...
      }: let
        cfg = config.yk8s;
      in {
        imports = [
          ./nix/vault.nix
          ./nix/load-balancing.nix
        ];
        options.yk8s = {
          _ansible.inventory_base_path = mkOption {
            description = ''
              Base path to the Ansible inventory. Files will get written here.
            '';
            type = types.str;
            default = "inventory/yaook-k8s/group_vars";
          };
        };
        config = {
        };
      });
  };
}
