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
        inherit (builtins) substring;
        inherit (pkgs.stdenv) mkDerivation;
        inherit (lib) types mkOption;
        inherit (lib.attrsets) filterAttrs mapAttrs' mapAttrsToList;
        inherit (lib.strings) concatLines;
        cfg = config.yk8s;
        mkInternalOption = args:
          mkOption ({
              internal = true;
              visible = false;
            }
            // args);
        filterInternal = filterAttrs (n: v: (substring 0 1 n) != "_");
        mkVars = sectionCfg:
          mapAttrs' (name: value: {
            name = "${sectionCfg._ansible_prefix}${name}";
            inherit value;
          }) (filterInternal sectionCfg);
        mkVarFile = sectionCfg: (pkgs.formats.yaml {}).generate sectionCfg._inventory_path (mkVars sectionCfg);
        mkInventory = cfg:
          mkDerivation {
            name = "yaook-group-vars";
            src = ./.;
            buildPhase = concatLines (mapAttrsToList (_: sectionCfg: ''
                install -m 644 -D ${mkVarFile sectionCfg} $out/${sectionCfg._inventory_path}
              '')
              (filterInternal cfg));
          };
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
          _package_name = mkInternalOption {
            default = "yk8s-inventory";
            type = types.str;
          };
          _warnings = mkInternalOption {
            type = types.listOf types.str;
          };
          _lib = {
            mkInternalOption = mkInternalOption {
              type = types.anything;
              default = mkInternalOption;
              # type = types.functionTo (types.functionTo types.attrs);
            };
          };
        };
        config = {
          packages."${cfg._package_name}" = mkInventory cfg;
        };
      });
  };
}
