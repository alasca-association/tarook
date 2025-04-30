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
        inherit (modules-lib) mkRemovedSectionModule;
        inherit (lib) types mkOption;
        inherit (yk8s-lib) mkInternalOption linkToPath baseSystemAssertWarn;
        cfg = config.yk8s;
      in {
        config._module.args = {
          inherit yk8s-lib;
          # Pin all packages used by this module to the version managed in the yaook/k8s repo
          pkgs = import inputs.yk8s.inputs.nixpkgs {
            inherit system;
          };
        };
        imports = [
          ./assertions.nix
          ./conf-vars.nix
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
          (mkRemovedSectionModule "passwordstore" "Passwordstore has been replaced by Vault.")
          (mkRemovedSectionModule "cah-users" "")
        ];
        options.yk8s = {
          state_directory = mkOption {
            description = ''
              The path to the cluster's state directory relative to the Nix file
              in which it is defined. Must be set to ./state or _state_base_path
              has to be adapted as well.
            '';
            type = with types; nullOr pathInStore;
            default = null;
            example = "state_directory = ./state; # from flake.nix";
          };
          _inventory_base_path = mkOption {
            description = ''
              Base path to the Ansible inventory. Files will get written here.
            '';
            type = types.nonEmptyStr;
            default = "inventory";
          };
          _state_base_path = mkOption {
            description = ''
              Base path to the state directory. Files will get written here.
            '';
            type = types.nonEmptyStr;
            default = "state";
          };
          _targets = mkInternalOption {
            type = with types;
              attrsOf (submodule {
                options = {
                  inventory_subdir = mkInternalOption {
                    description = ''
                      The directory inside _inventory_base_path in which inventory packages are to be created.
                    '';
                    type = with types; nullOr nonEmptyStr;
                  };
                  inventory_packages = mkInternalOption {
                    description = ''
                      Inventory packages from all sections that are then merged into the inventory directory
                    '';
                    type = with types; listOf package;
                    default = [];
                  };
                  state_packages = mkInternalOption {
                    description = ''
                      State packages from all sections that are then merged into the state directory
                    '';
                    type = with types; listOf package;
                    default = [];
                  };
                };
              });
          };
        };
        config.yk8s._targets.ansible.inventory_subdir = "yaook-k8s";
        config.yk8s.assertions =
          lib.mapAttrsToList (targetName: targetOptions: {
            assertion = (targetOptions.inventory_packages != []) -> targetOptions.inventory_subdir != null;
            message = "Target ${targetName} has inventory_packages, but inventory_subdir is not defined.";
          })
          cfg._targets;
        config.packages = lib.foldlAttrs (acc: targetName: targetOptions: let
          hasInventory = targetOptions.inventory_packages != [];
          inventory = pkgs.buildEnv {
            name = "yk8s-outputs-${targetName}-inventory";
            paths = targetOptions.inventory_packages;
          };
          state-dir = pkgs.buildEnv {
            name = "yk8s-outputs-${targetName}-state-dir";
            paths = targetOptions.state_packages;
          };
        in
          acc
          // {
            "yk8s-outputs-${targetName}" = builtins.seq (baseSystemAssertWarn config.yk8s) pkgs.buildEnv {
              name = "yk8s-outputs-${targetName}";
              paths = let
                inventoryPath = "${cfg._inventory_base_path}/${targetOptions.inventory_subdir}";
              in
                [
                  (pkgs.writeTextDir ".path-info"
                    ''
                      inventory=${
                        if hasInventory
                        then inventoryPath
                        else ""
                      }
                      state=${cfg._state_base_path}
                    '')
                  (linkToPath state-dir cfg._state_base_path)
                ]
                ++ lib.optional hasInventory
                (linkToPath inventory inventoryPath);
            };
          }) {}
        cfg._targets;
      });
  };
}
