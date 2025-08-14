{
  inputs,
  lib,
  self,
  flake-parts-lib,
  ...
}: {
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
        yk8s-lib = import ./lib {inherit lib pkgs;};
        modules-lib = import ./lib/modules.nix {inherit lib;};
        inherit (modules-lib) mkRemovedOptionModule;
        inherit (lib) types mkOption;
        inherit (yk8s-lib) mkInternalOption linkToPath baseSystemAssertWarn;
        inherit
          (yk8s-lib.types)
          relativePosixPath
          ;
        cfg = config.yk8s;
      in {
        config._module.args = {
          inherit yk8s-lib;
          # Pin all packages used by this module to the version managed in the Tarook repo
          pkgs = import inputs.yk8s.inputs.nixpkgs {
            inherit system;
          };
        };
        imports = [
          ./assertions.nix
          ./infra.nix
          ./terraform.nix
          ./openstack.nix
          ./vault.nix
          ./load-balancing.nix
          ./kubernetes
          ./node-scheduling.nix
          ./testing.nix
          ./custom.nix
          ./nvidia.nix
          ./miscellaneous.nix
          ./containerd.nix
          ./k8s-supplements
          (mkRemovedOptionModule ["passwordstore"] "Passwordstore has been replaced by Vault.")
          (mkRemovedOptionModule ["cah-users"] "")
        ];
        options.yk8s = {
          state_directory = mkOption {
            description = ''
              The path to the cluster's state directory relative to the Nix file
              in which it is defined. Must be set to ./state or _state_base_path
              has to be adapted as well.

              This is to be set in flake.nix.
            '';
            type = with types; nullOr pathInStore;
            default = null;
            example = lib.options.literalExpression "./state";
          };
          _inventory_base_path = mkOption {
            description = ''
              Base path to the Ansible inventory. Files will get written here.
            '';
            type = relativePosixPath;
            default = "inventory/yaook-k8s";
          };
          _state_base_path = mkOption {
            description = ''
              Base path to the state directory. Files will get written here.
            '';
            type = relativePosixPath;
            default = "state";
          };
          _inventory_packages = mkInternalOption {
            description = ''
              Inventory packages from all sections that are then merged into the inventory directory
            '';
            type = with types; listOf package;
            default = [];
          };
          _state_packages = mkInternalOption {
            description = ''
              State packages from all sections that are then merged into the state directory
            '';
            type = with types; listOf package;
            default = [];
          };
        };
        config.packages = rec {
          yk8s-inventory = pkgs.buildEnv {
            name = "yaook-k8s-inventory";
            paths = cfg._inventory_packages;
          };
          yk8s-state-dir = pkgs.buildEnv {
            name = "yaook-k8s-state-dir";
            paths = cfg._state_packages;
          };
          yk8s-outputs = builtins.seq (baseSystemAssertWarn config.yk8s) pkgs.buildEnv {
            name = "yaook-k8s-outputs";
            paths = [
              (linkToPath yk8s-inventory cfg._inventory_base_path)
              (linkToPath yk8s-state-dir cfg._state_base_path)
            ];
          };
        };
      });
  };
}
