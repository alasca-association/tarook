{localFlake}: {
  config,
  lib,
  self,
  flake-parts-lib,
  ...
}: let
  # TODO: disentangle the yk8s module from `system`
  # until then we need to hardcode x86_64-linux here which means that other platforms are not supported.
  # this is already in line with the systems we define in flake.nix, so no new constraint
  config' = config.allSystems.x86_64-linux;
  cfg = config'.yk8s.nixos;

  finalNixosNodes = lib.filterAttrs (_: v: v.os == "nixos") config'.yk8s.openstack.nodes; # TODO: get from yk8s.nodes instead
in {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({yk8s-lib, ...}: let
        inherit (yk8s-lib) types;
      in {
        options.yk8s.nixos = yk8s-lib.mkTopSection {
          sharedModules = lib.mkOption {
            description = ''
              NixOS modules that apply to all nodes
            '';
            type = with types; listOf anything;
            default = [];
          };
          groupModules = lib.mkOption {
            description = ''
              NixOS modules that apply to specific groups
            '';
            type = with types; attrsOf (listOf anything);
            default = {};
          };
          nodeModules = lib.mkOption {
            description = ''
              NixOS modules that apply to specific nodes
            '';
            type = with types; attrsOf (listOf anything);
            default = {};
          };
        };
        config = {
          yk8s.nixos.sharedModules =
            [
              {
                system.stateVersion = "26.05";
                nixpkgs.hostPlatform = "x86_64-linux";
              }
            ]
            ++ (
              lib.optional config'.yk8s.openstack.enabled
              ({modulesPath, ...}: {
                imports = ["${modulesPath}/virtualisation/openstack-config.nix"];
              })
            );
          packages = lib.optionalAttrs config'.yk8s.openstack.enabled (
            lib.mapAttrs' (
              hostname: _: {
                name = "vmImage-${hostname}";
                value = self.nixosConfigurations.${hostname}.config.system.build.images.openstack;
              }
            )
            finalNixosNodes
          );
        };
      });

    # TODO: assert that all nodes have a respective entry in yk8s.nodes with os == "nixos"
    # TODO: warn if group does not have a respective entry in yk8s.nodes with os == "nixos"
  };

  config = {
    flake = {
      nixosConfigurations = lib.mapAttrs (hostname: _: let
        modules = cfg.nodeModules.${hostname} or [];
      in
        localFlake.inputs.nixpkgs.lib.nixosSystem {
          modules = cfg.sharedModules ++ modules; # TODO: add group modules. get groups from yk8s.nodes
        })
      finalNixosNodes;
    };
  };
}
