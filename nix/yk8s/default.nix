{localFlake}: {
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
        inherit (lib) mkOption;
        inherit (yk8s-lib) mkInternalOption linkToPath baseSystemAssertWarn types;
        cfg = config.yk8s;
      in {
        config._module.args = {
          inherit yk8s-lib;
          terranix-lib = localFlake.inputs.terranix.lib;
          # Pin all packages used by this module to the version managed in the Tarook repo
          pkgs = import localFlake.inputs.nixpkgs {
            inherit system;
          };
        };
        imports = [
          ./conf-vars.nix
          ./infra.nix
          ./terraform.nix
          ./openstack
          ./vault.nix
          ./load-balancing.nix
          ./kubernetes
          ./node-scheduling.nix
          ./testing.nix
          ./custom.nix
          ./hooks.nix
          ./nvidia.nix
          ./miscellaneous.nix
          ./containerd.nix
          ./k8s-supplements
          (mkRemovedOptionModule ["passwordstore"] "Passwordstore has been replaced by Vault.")
          (mkRemovedOptionModule ["cah-users"] "")
        ];
        options.yk8s = let
          assertions = mkOption {
            type = with types; listOf unspecified;
            internal = true;
            default = [];
            example = [
              {
                assertion = false;
                message = "you can't enable this for that reason";
              }
            ];
            description = ''
              This option allows modules to express conditions that must
              hold for the evaluation of the system configuration to
              succeed, along with associated error messages for the user.
            '';
          };
          warnings = mkOption {
            internal = true;
            default = [];
            type = with types; listOf nonEmptyStr;
            example = ["The `foo' service is deprecated and will go away soon!"];
            description = ''
              This option allows modules to show warnings to users during
              the evaluation of the system configuration.
            '';
          };
        in {
          inherit assertions warnings;

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
            type = types.yk8s.posix.relativePath;
            default = "inventory";
          };
          _state_base_path = mkOption {
            description = ''
              Base path to the state directory. Files will get written here.
            '';
            type = types.yk8s.posix.relativePath;
            default = "state";
          };
          _targets = mkInternalOption {
            type = with types;
              attrsOf (submodule {
                options = {
                  inherit assertions warnings;

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
            "yk8s-outputs-${targetName}" =
              builtins.seq (baseSystemAssertWarn config.yk8s)
              builtins.seq (baseSystemAssertWarn targetOptions)
              pkgs.buildEnv {
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
