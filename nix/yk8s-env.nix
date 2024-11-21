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
          dependencies = let
            dependencyGroupModule = with lib.types;
              submodule {
                options = {
                  packages = lib.mkOption {
                    type = listOf package;
                    default = [];
                  };
                  depends = lib.mkOption {
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
            final = lib.mkOption {
              default = {};
              type = with lib.types;
                attrsOf dependencyGroupModule;
            };
          };
          environments = lib.mkOption {
            type = with lib.types; attrsOf package;
            default = {};
          };
        };

        imports = [./requirements.nix];

        config = {
          yk8s-env.dependencies.final = let
            mergedPackages = group:
              lib.unique (
                builtins.foldl' (
                  acc: dep: acc ++ (mergedPackages (builtins.getAttr dep cfg.dependencies.groups))
                ) (group.packages or []) (group.depends or [])
              );
          in
            lib.mapAttrs (_: group: {
              packages = mergedPackages group;
            })
            cfg.dependencies.groups;

          yk8s-env.environments =
            lib.mapAttrs (
              name: group:
                pkgs.buildEnv
                {
                  name = "yk8s-env-${name}";
                  paths = group.packages;
                }
            )
            cfg.dependencies.final;

          packages =
            lib.mapAttrs' (_: value: {
              inherit (value) name;
              inherit value;
            })
            cfg.environments;

          devShells =
            lib.mapAttrs (
              _: env:
                pkgs.mkShell {
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
