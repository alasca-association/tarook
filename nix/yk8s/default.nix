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
        inherit (lib) mkOption;
        inherit (yk8s-lib) mkInternalOption linkToPath baseSystemAssertWarn types;
        cfg = config.yk8s;
      in {
        config._module.args = {
          inherit yk8s-lib;
          terranix-lib = inputs.yk8s.inputs.terranix.lib;
          # Pin all packages used by this module to the version managed in the Tarook repo
          pkgs = import inputs.yk8s.inputs.nixpkgs {
            inherit system;
          };
        };
        imports = [
          ./conf-vars.nix
          ./infra.nix
          ./terraform.nix
          ./openstack
          ./proxmox
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
          ./pythonIFD.nix
          (mkRemovedOptionModule ["passwordstore"] "Passwordstore has been replaced by Vault.")
          (mkRemovedOptionModule ["cah-users"] "")
          (mkRemovedOptionModule ["state_directory"] ''


            # Don't change this except you know what you're doing
            yk8s.state_directory =
              if builtins.pathExists ./state
              then ./state
              else null;

            ^^^ REMOVE this block from your flake.nix
          '')
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

          _state_directory = mkInternalOption {
            readOnly = true;
            type = with types; nullOr pathInStore;
            default = let
              dir = "${self}/${cfg._state_base_path}";
            in
              if builtins.pathExists dir
              then dir
              else null;
          };
          _inventory_base_path = mkInternalOption {
            readOnly = true;
            description = ''
              Base path to the Ansible inventory relative to the flake root. Files will get written here.
            '';
            type = types.yk8s.posix.relativePath;
            default = "inventory";
          };
          _state_base_path = mkInternalOption {
            readOnly = true;
            description = ''
              Base path to the state directory relative to the flake root. Files will get written here.
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
