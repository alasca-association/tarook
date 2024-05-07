{
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) substring map trace isAttrs length head readDir attrNames filter foldl';
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib) mkOption;
  inherit (lib.attrsets) filterAttrs filterAttrsRecursive mapAttrs mapAttrs' mapAttrsToList foldlAttrs unionOfDisjoint recursiveUpdate setAttrByPath getAttrFromPath;
  inherit (lib.strings) concatLines;
  inherit (lib.sources) sourceFilesBySuffices;
  inherit (lib.trivial) id pipe;
in rec {
  types = let
    decimalOctetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])";
    ipv4AddrRE = "(${decimalOctetRE}\.){3}${decimalOctetRE}";
    ipv6SegmentRE = "[0-9a-fA-F]{1,4}";
    ipv6AddrRE =
      "("
      + "(${ipv6SegmentRE}:){7,7}${ipv6SegmentRE}|" # 1:2:3:4:5:6:7:8
      + "(${ipv6SegmentRE}:){1,7}:|" # 1::                                 1:2:3:4:5:6:7::
      + "(${ipv6SegmentRE}:){1,6}:${ipv6SegmentRE}|" # 1::8               1:2:3:4:5:6::8   1:2:3:4:5:6::8
      + "(${ipv6SegmentRE}:){1,5}(:${ipv6SegmentRE}){1,2}|" # 1::7:8             1:2:3:4:5::7:8   1:2:3:4:5::8
      + "(${ipv6SegmentRE}:){1,4}(:${ipv6SegmentRE}){1,3}|" # 1::6:7:8           1:2:3:4::6:7:8   1:2:3:4::8
      + "(${ipv6SegmentRE}:){1,3}(:${ipv6SegmentRE}){1,4}|" # 1::5:6:7:8         1:2:3::5:6:7:8   1:2:3::8
      + "(${ipv6SegmentRE}:){1,2}(:${ipv6SegmentRE}){1,5}|" # 1::4:5:6:7:8       1:2::4:5:6:7:8   1:2::8
      + "${ipv6SegmentRE}:((:${ipv6SegmentRE}){1,6})|" # 1::3:4:5:6:7:8     1::3:4:5:6:7:8   1::8
      + ":((:${ipv6SegmentRE}){1,7}|:)|" # ::2:3:4:5:6:7:8    ::2:3:4:5:6:7:8  ::8       ::
      + "fe80:(:${ipv6SegmentRE}){0,4}%[0-9a-zA-Z]{1,}|" # fe80::7:8%eth0     fe80::7:8%1  (link-local IPv6 addresses with zone index)
      + "::(ffff(:0{1,4}){0,1}:){0,1}${ipv4AddrRE}|" # ::255.255.255.255  ::ffff:255.255.255.255  ::ffff:0:255.255.255.255 (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
      + "(${ipv6SegmentRE}:){1,4}:${ipv4AddrRE}" # 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
      + ")";
  in {
    ipv4Addr = lib.types.strMatching "^${ipv4AddrRE}$";
    ipv4Cidr = lib.types.strMatching "^${ipv4AddrRE}/([0-9]|[12][0-9]|3[0-2])$";
    ipv6Addr = lib.types.strMatching "^${ipv6AddrRE}$";
    ipv6Cidr = lib.types.strMatching "^${ipv6AddrRE}/([0-9]|[1-9][0-9]|1[01][0-9]|12[0-8]$";
    k8sSize = lib.types.strMatching "[1-9][0-9]*([KMGT]i)?";
    k8sCpus = lib.types.strMatching "[1-9][0-9]*m?";
    k8sServiceType = lib.types.strMatching "ClusterIP|NodeIP|LoadBalancer";
  };
  mkInternalOption = args:
    mkOption ({
        internal = true;
        visible = false;
      }
      // args);
  mkTopSection = options: ({
      _internal = {
        removedOptions = mkInternalOption {
          type = with lib.types; listOf (listOf str);
          default = [];
        };
      };
    }
    // options);
  mkResourceOptions = {
    sectionCfg,
    prefix,
    description,
    cpu,
    memory,
  }: {
    # TODO: deprecate cpu limit (because it shouldnt be set)
    "${prefix}_cpu_limit" = mkOption {
      inherit description;
      type = lib.types.nullOr types.k8sCpus;
      default = null;
    };
    "${prefix}_cpu_request" = mkOption {
      inherit description;
      type = lib.types.nullOr types.k8sCpus;
      default = cpu.request;
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    "${prefix}_memory_request" = mkOption {
      inherit description;
      type = lib.types.nullOr types.k8sSize;
      default = sectionCfg."${prefix}_memory_limit";
      defaultText = ''
        ''${"${prefix}_memory_limit"}
      '';
    };
    "${prefix}_memory_limit" = mkOption {
      inherit description;
      type = lib.types.nullOr types.k8sSize;
      default = memory.limit;
    };
  };
  mkMultiResourceOptions = {
    sectionCfg,
    description,
    resources,
  }:
    foldlAttrs (acc: prefix: values:
      acc
      // (mkResourceOptions {
        inherit sectionCfg description prefix;
        inherit (values) cpu memory;
      })) {}
    resources;
  mkGroupVarsFile = {
    cfg,
    inventory_path,
    ansible_prefix ? "",
    only_if_enabled ? false,
    transformations ? [],
    # flatten ? 1, # TODO
  }: let
    path = "group_vars/${inventory_path}";
    finalConfig = with transform;
      pipe cfg (
        (lib.optional only_if_enabled onlyIfEnabled)
        ++ [removeObsoleteOptions filterInternal]
        ++ transformations
        ++ [flatten (addPrefix ansible_prefix)]
      );
  in
    mkDerivation {
      name = "yaook-k8s-" + path;
      src = ./.;
      preferLocalBuild = true;
      buildPhase = builtins.traceVerbose "Writing file: ${path}" ''
        install -m 644 -D ${mkYaml path finalConfig} $out/${path}
      '';
    };
  mkYaml = (pkgs.formats.yaml {}).generate;
  linkToPath = file: path:
    pkgs.runCommandLocal path {} ''
      mkdir -p $(dirname $out/${path})
      ln -s ${file} $out/${path}
    '';
  transform = rec {
    /*
    Remove all options from cfg that are listed in cfg._internal.removedOptions
    */
    removeObsoleteOptions = cfg:
      if builtins.hasAttr "_internal" cfg
      then removeAttrsByPath cfg cfg._internal.removedOptions
      else cfg;

    /*
    Remove multiple attributes listed by path in list from set. The attribute doesn't have to exist in set. For instance,

      removeAttrByPath {a = { a1 = 1; a2 = 2; }; b = {b1=1; b2=2; }; } [ ["a" "a1"] ["b" "b1"] ]
      -> {a = {a2 = 2;}; b = {b2 = 2;}; }

    */
    removeAttrsByPath = builtins.foldl' removeAttrByPath;

    /*
    Remove the attribute listed by path in list from set. The attribute doesn't have to exist in set. For instance,

      removeAttrByPath {a.b.c = {d=1; e=2;};} [ "a" "b" "c" "d" ]
      -> {a = {b = { c = { e = 2; }; }; }; }
    */
    removeAttrByPath = attrs: path: let
      inherit (builtins) sub length tail removeAttrs;
      inherit (lib.lists) take;
      inherit (lib.attrsets) updateManyAttrsByPath;
      l = length path;
      p = take (sub l 1) path;
      e = tail path;
    in
      if l == 1
      then removeAttrs attrs path
      else
        updateManyAttrsByPath [
          {
            path = p;
            update = old: (removeAttrs old e);
          }
        ]
        attrs;

    filterInternal = filterAttrs (n: _: n != "_internal");
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
    onlyIfEnabled = cfg:
      if ! cfg.enabled
      then {enabled = false;}
      else cfg;
    addPrefix = prefix:
      mapAttrs' (name: value: {
        name = "${prefix}${name}";
        inherit value;
      });
  };
}
