{flake-parts-lib, ...}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        pkgs,
        lib,
        inputs',
        ...
      }: let
        cfg = config.yk8s-env;
      in {
        options.yk8s-env = {
          python = lib.mkOption {
            type = lib.types.package;
          };
          dependencies = let
            dependencyGroupModule = with lib.types;
              submodule {
                options = {
                  packages = lib.mkOption {
                    type = listOf package;
                    default = [];
                  };
                  pythonPackages = lib.mkOption {
                    type = functionTo (listOf package);
                    default = ps: [];
                  };
                  includes = lib.mkOption {
                    type = listOf str;
                    default = [];
                  };
                };
              };
          in {
            groups = lib.mkOption {
              default = {};
              type = with lib.types;
                attrsOf dependencyGroupModule;
            };
            finalGroups = lib.mkOption {
              readOnly = true;
              type = with lib.types;
                attrsOf dependencyGroupModule;
            };
          };
          environments = lib.mkOption {
            type = with lib.types; attrsOf package;
            default = {};
          };
        };

        imports = [./dependencies.nix];

        config = {
          yk8s-env.dependencies.finalGroups = let
            mergedPackages = group:
              lib.unique (
                builtins.foldl' (
                  acc: dep: acc ++ (mergedPackages (builtins.getAttr dep cfg.dependencies.groups))
                )
                group.packages
                group.includes
              );
            mergedPythonPackages = group: ps:
              lib.unique (
                builtins.foldl' (
                  acc: dep: acc ++ (mergedPythonPackages (builtins.getAttr dep cfg.dependencies.groups) ps)
                ) (group.pythonPackages ps)
                group.includes
              );
          in
            lib.mapAttrs (_: group: {
              packages = mergedPackages group;
              pythonPackages = mergedPythonPackages group;
            })
            cfg.dependencies.groups;

          yk8s-env.environments =
            lib.mapAttrs (
              name: group:
                pkgs.buildEnv
                {
                  name = "yk8s-env-${name}";
                  paths = (group.packages) ++ [(cfg.python.withPackages (group.pythonPackages))];
                }
            )
            cfg.dependencies.finalGroups;

          packages =
            lib.mapAttrs' (_: value: {
              inherit (value) name;
              inherit value;
            })
            cfg.environments;

          devShells =
            lib.mapAttrs (
              _: env:
                pkgs.mkShellNoCC {
                  buildInputs = [
                    env
                  ];
                }
            )
            cfg.environments;
        };
      });
  };
}
