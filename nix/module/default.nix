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
        inherit (builtins) substring map trace isAttrs length head readDir attrNames;
        inherit (pkgs.stdenv) mkDerivation;
        inherit (lib) types mkOption;
        inherit (lib.attrsets) filterAttrs filterAttrsRecursive mapAttrs' mapAttrsToList foldlAttrs;
        inherit (lib.strings) concatLines;
        inherit (lib.sources) sourceFilesBySuffices;
        inherit (lib.trivial) id pipe;
        cfg = config.yk8s;
        mkInternalOption = args:
          mkOption ({
              internal = true;
              visible = false;
            }
            // args);
        mkContainerSection = options: ({
            _sectiontype = mkInternalOption {
              default = "container";
              type = types.str;
            };
          }
          // options);
        mkTopSection = options: ({
            _sectiontype = mkInternalOption {
              default = "config";
              type = types.str;
            };
            _ansible_prefix = mkInternalOption {
              default = "";
              type = types.str;
            };
            _inventory_path = mkInternalOption {
              type = types.str;
            };
            _only_if_enabled = mkInternalOption {
              description = ''
                If true, the whole section is omitted from the file, except for the `enabled` value.
              '';
              type = types.bool;
              default = false;
            };
            _variable_transformation = mkInternalOption {
              type = types.functionTo types.attrs;
              default = id;
            };
          }
          // options);
        filterInternal = filterAttrs (n: _: (substring 0 1 n) != "_");
        filterNull = filterAttrsRecursive (_: v: v != null);
        flatten = foldlAttrs (
          acc: outerName: outerValue:
            acc
            // (
              if isAttrs outerValue
              then
                mapAttrs' (name: value: {
                  name = "${outerName}_${name}";
                  inherit value;
                }) (flatten outerValue)
              else {"${outerName}" = outerValue;}
            )
        ) {};
        filterDisabled = sectionCfg:
          if sectionCfg._only_if_enabled && ! sectionCfg.enabled
          then {enabled = false;}
          else sectionCfg;
        applyFilters = sectionCfg: pipe sectionCfg [sectionCfg._variable_transformation filterDisabled filterInternal flatten filterNull];
        mkVars = sectionCfg:
          mapAttrs' (name: value: {
            name = "${sectionCfg._ansible_prefix}${name}";
            inherit value;
          }) (applyFilters sectionCfg);
        mkVarFile = sectionCfg: (pkgs.formats.yaml {}).generate sectionCfg._inventory_path (mkVars (sectionCfg._variable_transformation sectionCfg));
        mkInventory = cfg:
          mkDerivation {
            name = "yaook-group-vars";
            src = ./.;
            preferLocalBuild = true;
            buildPhase = concatLines (mapAttrsToList (section: sectionCfg:
              trace "Section in process: ${section}" ''
                install -m 644 -D ${mkVarFile sectionCfg} $out/${sectionCfg._inventory_path}
              '')
            (filterInternal cfg));
            checkPhase = let
              warnings = concatLines (map (w: "# ${builtins.trace "WARNING: ${w}" w}") cfg._warnings);
              errors = concatLines (map (e: "# ${builtins.trace "ERROR: ${e}" e}") cfg._errors);
            in
              warnings
              + (
                if cfg._errors == []
                then ""
                else if length cfg._errors == 1
                then throw (head cfg._errors)
                else throw (concatLines ["Multiple errors have been encountered:"] ++ errors)
              );
          };
      in {
        imports = [
          # ./terraform.nix
          ./vault.nix
          ./load-balancing.nix
          ./wireguard.nix
          ./ch-k8s-lbaas.nix
          ./kubernetes
          ./node-scheduling.nix
          ./testing.nix
          ./ipsec.nix
          # ./custom.nix
          ./nvidia.nix
          ./miscellaneous.nix
          ./k8s-supplements.nix
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
            default = [];
            type = types.listOf types.str;
          };
          _errors = mkInternalOption {
            default = [];
            type = types.listOf types.str;
          };
          _lib = {
            types = mkInternalOption {
              type = types.attrs;
              default = {
                ipv4Addr = types.strMatching "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$";
                ipv4Cidr = types.strMatching "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}/([0-9]|[12][0-9]|3[0-2])$";
              };
            };
            mkInternalOption = mkInternalOption {
              type = types.functionTo types.attrs;
              default = mkInternalOption;
            };
            mkVars = mkInternalOption {
              type = types.functionTo types.attrs;
              default = mkVars;
            };
            mkTopSection = mkInternalOption {
              type = types.functionTo types.attrs;
              default = mkTopSection;
            };
            mkContainerSection = mkInternalOption {
              type = types.functionTo types.attrs;
              default = mkContainerSection;
            };
            logIf = mkInternalOption {
              type = types.functionTo types.anything;
              default = cond: msg: lib.optionals cond [msg];
            };
          };
        };
        config = {
          packages."${cfg._package_name}" = mkInventory cfg;
        };
      });
  };
}
