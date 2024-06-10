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
        inherit (builtins) substring map trace isAttrs length head readDir attrNames filter foldl';
        inherit (pkgs.stdenv) mkDerivation;
        inherit (lib) types mkOption;
        inherit (lib.attrsets) filterAttrs filterAttrsRecursive mapAttrs mapAttrs' mapAttrsToList foldlAttrs unionOfDisjoint recursiveUpdate;
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
        filterNull = withExported (filterAttrsRecursive (_: v: v != null));
        flatten = withExported (foldlAttrs (
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
        ) {});
        filterDisabled = sectionCfg:
          withExported (
            cfg:
              if sectionCfg._only_if_enabled && ! cfg.enabled
              then trace "${sectionCfg._name} is disabled" {enabled = false;}
              else {}
          )
          sectionCfg;
        applyFilters = sectionCfg: pipe sectionCfg [filterDisabled sectionCfg._variable_transformation flatten filterNull addPrefix];
        addPrefix = sectionCfg:
          withExported (
            mapAttrs' (name: value: {
              name = "${sectionCfg._ansible_prefix}${name}";
              inherit value;
            })
          )
          sectionCfg;
        withExported = func:
          mapAttrs (n: v:
            if n == "exported"
            then func v
            else v);
        mkSectionSet = name: config:
          {_name = name;}
          // (foldlAttrs (acc: n: v:
            recursiveUpdate acc (
              if (substring 0 1 n) == "_"
              then {
                ${n} = v;
              }
              else {exported.${n} = v;}
            )) {}
          config);
        mkVarFile = (pkgs.formats.yaml {}).generate;
        getSections = foldlAttrs (acc: name: val:
          acc
          ++ (
            if (val ? "_sectiontype" && val._sectiontype == "config")
            then trace "Found config section ${name}" [(mkSectionSet name val)]
            else if (val ? "_sectiontype" && val._sectiontype == "container")
            then trace "Found container section ${name}" (getSections val)
            else []
          )) [];
        getExportedConfigs = cfg: filter (sectionCfg: sectionCfg ? "exported" && sectionCfg.exported != {}) (map applyFilters (getSections cfg));
        groupExportedByPath = cfg: foldl' (acc: sectionCfg: unionOfDisjoint acc {${sectionCfg._inventory_path} = sectionCfg.exported;}) {} (getExportedConfigs cfg);
        mkInventory = cfg:
          mkDerivation {
            name = "yaook-group-vars";
            src = ./.;
            preferLocalBuild = true;
            buildPhase = concatLines (mapAttrsToList (inventoryPath: finalSectionCfg:
              trace "Writing file: ${inventoryPath}" ''
                install -m 644 -D ${mkVarFile inventoryPath finalSectionCfg} $out/${inventoryPath}
              '')
            (groupExportedByPath cfg));
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
          ./custom.nix
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
