{lib, ...}:
with lib; let
  options-lib = import ./options.nix {inherit lib;};
in rec {
  /*
     Return a module that causes a warning to be shown if the
     specified option is defined. For example,

     mkRemovedOptionModule "kubernetes" "use_podsecuritypolicies" "<replacement instructions>"

     causes a assertion if the user defines kubernetes.use_podsecuritypolicies.

     replacementInstructions is a string that provides instructions on
     how to achieve the same functionality without the removed option,
     or alternatively a reasoning why the functionality is not needed.
     replacementInstructions SHOULD be provided!

  (Adapted from https://github.com/nixos/nixpkgs/blob/master/lib/modules.nix)
  */
  mkRemovedOptionModule = sectionName: optionName: replacementInstructions: {options, ...}: let
    section = splitString "." sectionName;
    option = splitString "." optionName;
    absOptionName = ["yk8s"] ++ section ++ option;
  in {
    options = setAttrByPath absOptionName (mkOption {
      visible = false;
      apply = x: throw "The option `${showOption absOptionName}' can no longer be used since it's been removed. ${replacementInstructions}";
    });
    config.yk8s =
      {
        assertions = let
          opt = getAttrFromPath absOptionName options;
        in [
          {
            assertion = !opt.isDefined;
            message = ''
              The option definition `${showOption absOptionName}' in ${showFiles opt.files} no longer has any effect; please remove it.
              ${replacementInstructions}
            '';
          }
        ];
      }
      // setAttrByPath section {_internal.removedOptions = [option];};
  };

  /*
  Return a module that causes a warning to be shown if the
  specified section is defined. For example,

  mkRemovedOptionModule "passwordstore" "<replacement instructions>"

  causes a assertion if the user defines passwordstore.

  replacementInstructions is a string that provides instructions on
  how to achieve the same functionality without the removed option,
  or alternatively a reasoning why the functionality is not needed.
  replacementInstructions SHOULD be provided!

  */
  mkRemovedSectionModule = sectionName: replacementInstructions: {options, ...}: let
    section = splitString "." sectionName;
    absSectionName = ["yk8s"] ++ section;
  in {
    options = setAttrByPath absSectionName (mkOption {
      visible = false;
      apply = x: throw "The section `${showOption absSectionName}' can no longer be used since it's been removed. ${replacementInstructions}";
    });
    config.yk8s = {
      assertions = let
        opt = getAttrFromPath absSectionName options;
      in [
        {
          assertion = !opt.isDefined;
          message = ''
            The section definition `${showOption absSectionName}' in ${showFiles opt.files} no longer has any effect; please remove it.
            ${replacementInstructions}
          '';
        }
      ];
    };
  };

  /*
  Return a list of modules that causes warnings to be shown if a resource option
  of the form ${prefix}_[memory|cpu]_[request|limit] is used, the defined value
  however forwarded to${prefix}_resources.[memory|cpu].[request|limit].
  For example,

    imports = [
      ....
    ] ++
    (mkRenamedResourceOptionModules "k8s-service-layer.rook" ["mon" "osd" "mgr" "mds" "operator"]);
  */
  mkRenamedResourceOptionModules = section: prefix:
    lib.mapCartesianProduct ({
      prefix,
      res,
      type,
    }: (
      mkRenamedOptionModule section "${prefix}_${res}_${type}" "${prefix}_resources.${type}s.${res}"
    )) {
      inherit prefix;
      res = ["memory" "cpu"];
      type = ["request" "limit"];
    };

  /*
  Return a module that causes a warning to be shown if the
  specified "from" option is defined; the defined value is however
  forwarded to the "to" option. This can be used to rename options
  while providing backward compatibility. For example,

    imports = [
      (mkRenamedOptionModule "wireguard" "wg_ip_cidr" "ip_cidr")
    ];

  forwards any definitions of wireguard.wg_ip_cidr to
  wireguard.ip_cidr while printing a warning.

  This also copies over the priority from the aliased option to the
  non-aliased option.
  */
  mkRenamedOptionModule = sectionName: from: to: (mkRenamedOptionModuleWithNewSection sectionName from sectionName to);

  /*
  Return a module that causes a warning to be shown if the
  specified "from" option is defined; the defined value is however
  forwarded to the "to" option. This can be used to rename options
  while providing backward compatibility. For example,

    imports = [
      (mkRenamedOptionModuleWithNewSection "sec1" "op1" "sec2" "op1")
    ]

  forwards any definitions of wireguard.wg_ip_cidr to
  wireguard.ip_cidr while printing a warning.

  This also copies over the priority from the aliased option to the
  non-aliased option.
  */
  mkRenamedOptionModuleWithNewSection = sectionNameFrom: from: sectionNameTo: to: let
    sectionFrom = splitString "." sectionNameFrom;
    sectionTo = splitString "." sectionNameTo;
    from' = splitString "." from;
    to' = splitString "." to;
    fromWithSection = sectionFrom ++ from';
    toWithSection = sectionTo ++ to';
    absFrom = ["yk8s"] ++ fromWithSection;
    absTo = ["yk8s"] ++ toWithSection;
  in {
    imports = [
      (doRename {
        from = absFrom;
        to = absTo;
        visible = false;
        warn = true;
        use = builtins.trace "Obsolete option `${showOption fromWithSection}' is used. It was renamed to `${showOption toWithSection}'.";
      })
      {
        config.yk8s = setAttrByPath sectionFrom {_internal.removedOptions = [from'];};
      }
      ({options, ...}: {
        config.yk8s.warnings = let
          fromOpt = getAttrFromPath absFrom options;
        in
          lib.optional (fromOpt.isDefined)
          "The option `${showOption absFrom}' defined in ${showFiles fromOpt.files} has been renamed to `${showOption absTo}'.";
      })
    ];
  };

  checkResources = absOpt: {options, ...}: let
    cpuLimit = attrByPath (absOpt ++ ["value" "cpu" "limit"]) null options;
    memoryRequest = attrByPath (absOpt ++ ["value" "memory" "request"]) null options;
    memoryLimit = attrByPath (absOpt ++ ["value" "cpu" "limit"]) null options;
    optLoc = concatStringsSep "." absOpt;
  in {
    config.yk8s.warnings =
      (optional (cpuLimit != null) "A CPU Limit has been set at `${optLoc}`. This is not recommended.")
      ++ (
        optional
        ((memoryRequest != null) && (memoryLimit != null) && (memoryLimit != memoryRequest))
        "Memory request and memory limit have been set to different values at `${optLoc}`. This is not recommended."
      );
  };

  mkResourceOptionModule = sectionName: optionName: resources: let
    sec = ["yk8s"] ++ (splitString "." sectionName);
    opt =
      if length (splitString "." optionName) == 1
      then [optionName]
      else abort "mkResouceOptionModule doesn't currently support nested optionNames (at ${sectionName}.${optionName})";
    absOpt = sec ++ opt;
  in {
    options = setAttrByPath absOpt (options-lib.mkResourceOption resources);
    config = setAttrByPath (sec ++ ["_internal" "unflat"]) opt;
    imports = [
      (checkResources absOpt)
    ];
  };

  mkMultiResourceOptionsModule = sectionName: opts: let
    sec = ["yk8s"] ++ (splitString "." sectionName);
    names = attrNames opts.resources;
  in {
    options = setAttrByPath sec (options-lib.mkMultiResourceOptions opts);
    config = setAttrByPath (sec ++ ["_internal" "unflat"]) (map (n: "${n}_resources") names);
    imports = map (name: checkResources (sec ++ [name])) names;
  };
}
