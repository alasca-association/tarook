{flake-parts-lib, ...}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        pkgs,
        lib,
        ...
      }: let
        cfg = config.yk8s-env;

        commonOptions = with lib.types; {
          description = lib.mkOption {
            description = ''
              The description of the dependency group
            '';
            type = lib.nullOr lib.str;
            default = null;
          };
          packages = lib.mkOption {
            description = ''
              Non-python dependencies of the group
            '';
            type = listOf package;
            default = [];
          };
          pythonPackages = lib.mkOption {
            description = ''
              Python dependencies of the group
            '';
            type = functionTo (listOf package);
            default = ps: [];
          };
        };
      in {
        options.yk8s-env = {
          python = lib.mkOption {
            type = lib.types.package;
          };
          dependencies = {
            groups = lib.mkOption {
              description = ''
                Dependencies for yk8s are organized in groups, so for each purpose, only the
                minimal amount of dependencies has to be loaded. Groups can contain Python
                dependencies, non-Python dependencies and they can include other groups in a directed acyclic graph.
              '';
              default = {};
              type = with lib.types;
                attrsOf (submodule {
                  options =
                    commonOptions
                    // {
                      extraPythonPackages = lib.mkOption {
                        description = ''
                          A list of additional Python dependencies of the group
                        '';
                        type = listOf (functionTo (listOf package));
                        default = [];
                      };
                      includes = lib.mkOption {
                        description = ''
                          A list of group names that should be included by this group.
                          Dependencies of all included groups will be merged into the
                          dependencies of this group.
                        '';
                        type = listOf str;
                        default = [];
                      };
                    };
                });
            };
            finalGroups = lib.mkOption {
              description = ''
                Read-only option that can be used to get the final lists of packages that are available in a given group.
              '';
              readOnly = true;
              type = with lib.types;
                attrsOf (submodule {
                  options = commonOptions;
                });
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
            flattenPythonPackages = ps: builtins.foldl' (acc: f: acc ++ f ps) [];
            mergedPythonPackages = group: ps:
              lib.unique (
                builtins.foldl' (
                  acc: dep: acc ++ (mergedPythonPackages (builtins.getAttr dep cfg.dependencies.groups) ps)
                ) (group.pythonPackages ps ++ flattenPythonPackages ps group.extraPythonPackages)
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
            (lib.mapAttrs' (_: value: {
                inherit (value) name;
                inherit value;
              })
              cfg.environments)
            // {inherit (pkgs) glibcLocales;};

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
