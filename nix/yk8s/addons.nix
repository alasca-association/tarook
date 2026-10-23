{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s._addons;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkInternalOption types;
in {
  options.yk8s._addons = mkInternalOption {
    type = with types;
      attrsOf (submodule {
        options = {
          type = mkOption {
            description = ''
              The type of the addon.
            '';
            type = enum ["playbook" "command"];
          };
          path = mkOption {
            description = ''
              The path to the playbook or command.

              Note that commands must be self-contained.
              If additional dependencies are necessary, commands must be wrapped with e.g. mkDerivation or writeShellApplication
            '';
            type = pathInStore;
          };
          playbook = {
            role_paths = mkOption {
              type = with types; listOf pathInStore;
            };
            inventory_packages = mkOption {
              type = with types; listOf package;
              default = [];
            };
            requirements = mkOption {
              description = ''
                (Only for playbook addons)

                Roles and collections on which this addon depends to install via Ansible Galaxy.
                https://docs.ansible.com/projects/ansible/latest/galaxy/user_guide.html#installing-roles-and-collections-from-the-same-requirements-yml-file
              '';
              type = submodule {
                options = {
                  roles = lib.mkOption {
                    type = listOf attrs;
                  };
                  collections = lib.mkOption {
                    type = listOf attrs;
                  };
                };
              };
            };
          };
          after = mkOption {
            description = ''
              Ensure that this addon is applied after the ones provided in this list.
            '';
            type = listOf nonEmptyStr;
            default = [];
          };
          before = mkOption {
            description = ''
              Ensure that this addon is applied before the ones provided in this list.
            '';
            type = listOf nonEmptyStr;
            default = [];
          };
          assertions = mkOption {
            type = with types; listOf unspecified;
            default = [];
            example = [
              {
                assertion = false;
                message = "you can't enable this for that reason";
              }
            ];
            description = ''
              This option allows addons to express conditions that must
              hold for the evaluation of the configuration to
              succeed, along with associated error messages for the user.
            '';
          };
          warnings = mkOption {
            default = [];
            type = with types; listOf nonEmptyStr;
            example = ["The `foo' service is deprecated and will go away soon!"];
            description = ''
              This option allows addons to show warnings to users during
              the evaluation of the configuration.
            '';
          };
        };
      });
  };
  config.yk8s._targets.addons = {
    assertions = lib.flatten (lib.mapAttrsToList (_: addon: addon.assertions) cfg);
    warnings = lib.flatten (lib.mapAttrsToList (_: addon: addon.warnings) cfg);
    inventory_subdir = "addons";
    inventory_packages =
      [
        (yk8s-lib.mkYamlAtPath "main.yaml" cfg)
      ]
      ++ (lib.mapAttrsToList (
        name: addon:
          yk8s-lib.linkToPath
          (pkgs.buildEnv {
            name = "yk8s-outputs-addons-${name}-inventory";
            paths = config.yk8s._targets.ansible.inventory_packages ++ addon.playbook.inventory_packages;
          }).outPath "${name}"
      ) (lib.filterAttrs (_: addon: addon.type == "playbook") cfg));
  };
}
