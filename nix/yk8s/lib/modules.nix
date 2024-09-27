{lib, ...}:
with lib; let
  yk8s-lib.transform = import ./transform.nix {inherit lib;};
  yk8s-lib.types = import ./types.nix {inherit lib;};
  yk8s-lib.options = import ./options.nix {inherit lib;};
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

  /*
  Return a module that causes warnings to be shown if best practices have been
  violated by
  * setting a CPU limit or
  * setting memory reqeusts and limits to different values

  This module is intended to be used by mkResourceOptionModule
  */
  checkResources = absOpt: {config, ...}: let
    cpuLimit = attrByPath (absOpt ++ ["limits" "cpu"]) null config;
    memoryRequest = attrByPath (absOpt ++ ["requests" "memory"]) null config;
    memoryLimit = attrByPath (absOpt ++ ["limits" "cpu"]) null config;
    optLoc = concatStringsSep "." absOpt;
  in {
    config.yk8s.warnings =
      (optional ((builtins.seq cpuLimit cpuLimit) != null) "A CPU Limit has been set at `${optLoc}`. This is not recommended.")
      ++ (
        optional
        ((memoryRequest != null) && (memoryLimit != null) && (memoryLimit != memoryRequest))
        "Memory request and memory limit have been set to different values at `${optLoc}`. This is not recommended."
      );
  };

  /*
  Returns a module that adds a resource option which mirrors the layout of
  the "resource" field in podSpecs. By default all values are unset. If a memory
  limit has been set, the memory request will by default be set to the same value.

  Example usage:

    imports = [
      (mkResourceOptionModule "ch-k8s-lbaas" "controller_resources" {
        description = "Request and limit for the LBaaS controller";
        cpu.request = "100m";
        memory.limit = "256Mi";
      })
    ];
  */
  mkResourceOptionModule = sectionName: optionName: {
    description,
    cpu,
    memory,
  }: let
    sec = ["yk8s"] ++ (splitString "." sectionName);
    opt =
      if length (splitString "." optionName) == 1
      then [optionName]
      else abort "mkResouceOptionModule doesn't currently support nested optionNames (at ${sectionName}.${optionName})";
    absOpt = sec ++ opt;
  in
    {config, ...}: {
      options = setAttrByPath absOpt (lib.mkOption {
        default = {};
        type = lib.types.submodule {
          options = {
            limits.cpu = lib.mkOption {
              description = ''
                CPU limits should never be set.

                Thus, this option is deprecated.
              '';
              type = lib.types.nullOr yk8s-lib.types.k8sCpus;
              default = cpu.limit or null;
            };
            requests.cpu = lib.mkOption {
              inherit description;
              type = lib.types.nullOr yk8s-lib.types.k8sCpus;
              default = cpu.request or null;
              example = cpu.example or null;
            };

            requests.memory = lib.mkOption {
              description = ''
                Memory requests should always be equal to the limits.

                Thus, this option is deprecated.
              '';
              type = lib.types.nullOr yk8s-lib.types.k8sSize;
              default = memory.request or (attrByPath (absOpt ++ ["limits" "memory"]) null config);
              defaultText = memory.request or "\${${lib.strings.concatStringsSep "." (["config"] ++ absOpt ++ ["limits" "memory"])}}";
            };
            limits.memory = lib.mkOption {
              inherit description;
              type = lib.types.nullOr yk8s-lib.types.k8sSize;
              default = memory.limit or null;
              example = memory.example or null;
            };
          };
        };
        apply = yk8s-lib.transform.filterNull;
      });
      config = setAttrByPath (sec ++ ["_internal" "unflat"]) opt;
      imports = [
        (checkResources absOpt)
      ];
    };

  /*
  Returns a module that sets multiple resource options. For brevity only one description
  can be set that will be applied to all options.

  For example
   imports =
      [
        (mkMultiResourceOptionsModule "k8s-service-layer.rook" {
          description = ''
            Requests and limits for rook/ceph

            The default values are the *absolute minimum* values required by rook. Going
            below these numbers will make rook refuse to even create the pods. See also:
            https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings
          '';
          resources = {
            mon.cpu.request = "100m";
            mon.memory.limit = "1Gi";

            osd.cpu.request = null;
            osd.memory.limit = "2Gi";

            mgr.cpu.request = "100m";
            mgr.memory.limit = "512Mi";

            mds.cpu.request = null;
            mds.memory.limit = "4Gi";

            operator.cpu.request = null;
            operator.memory.limit = "512Mi";
          };
        })
  */
  mkMultiResourceOptionsModule = sectionName: {
    description,
    resources,
  }: let
    sec = ["yk8s"] ++ (splitString "." sectionName);
    names = attrNames resources;
  in {
    imports = lib.attrsets.foldlAttrs (acc: prefix: values:
      acc
      ++ [
        (mkResourceOptionModule sectionName "${prefix}_resources" {
          inherit description;
          inherit (values) cpu memory;
        })
      ]) []
    resources;
  };

  /*
  Return a module that adds three options values, default_values and extra_values.

  It takes the top section as its first argument and a prefix as its second. The
  prefix will be prepended to either option name and may contain subsections
  separated by dots.

  The options that are added are:

  default_values is an internal option. It will be pre-filled inside the LCM with
  the values from the configuration.
  This option will not be passed to the inventory.

  extra_values is the place where additional values can be passed that
  are not directly exposed by the LCM.
  This option will not be passed to the inventory.

  values is the attribute set that is finally passed to Helm. It is the result of
  merging default_values and extra_values.
  It will be exempt from flattening.

  For example
   imports =
      [
        (mkHelmValuesModule "nvidia" "device_plugin"
      ]
  */

  mkHelmValuesModule = sectionName: prefix: let
    sec = ["yk8s"] ++ (splitString "." sectionName);
    splitPrefix = splitString "." prefix;
    opt =
      if (builtins.length splitPrefix) > 1
      then init splitPrefix
      else [];
    finalPrefix = last splitPrefix;
    valuesOpt =
      if finalPrefix != ""
      then "${finalPrefix}_values"
      else "values";
    extraValuesOpt =
      if finalPrefix != ""
      then "${finalPrefix}_extra_values"
      else "extra_values";
    defaultValuesOpt =
      if finalPrefix != ""
      then "${finalPrefix}_default_values"
      else "default_values";
  in
    {config, ...}: {
      options =
        lib.recursiveUpdate
        (setAttrByPath (sec ++ opt ++ [valuesOpt]) (lib.mkOption {
          description = ''
            These are the values that are passed to Helm. You most likely do not want to
            set them directly as that would override all values set by the LCM.

            Use the respective extra_values instead.
          '';
          type = lib.types.attrs;
          default = {};
        }))
        (lib.recursiveUpdate
          (setAttrByPath (sec ++ opt ++ [defaultValuesOpt]) (yk8s-lib.options.mkInternalOption {
            description = ''
              These are the default values set inside the module. They will be merged with extraValues and be exposed in values.
            '';
            type = lib.types.attrs;
            default = {};
          }))
          (setAttrByPath (sec ++ opt ++ [extraValuesOpt]) (lib.mkOption {
            description = ''
              Any additional values that should be passed to the Helm chart. Will not be checked.

              When the same value is set by the LCM and by extra_values, then extra_values takes precedence.
            '';
            type = lib.types.attrs;
            default = {};
          })));
      config = lib.mkMerge [
        (setAttrByPath (sec ++ ["_internal" "unflat"]) [valuesOpt])
        (setAttrByPath (sec ++ ["_internal" "removedOptions"]) [(opt ++ [defaultValuesOpt]) (opt ++ [extraValuesOpt])])
        (
          setAttrByPath (sec ++ opt ++ [valuesOpt]) (
            lib.recursiveUpdate
            (getAttrFromPath (sec ++ opt ++ [defaultValuesOpt]) config)
            (getAttrFromPath (sec ++ opt ++ [extraValuesOpt]) config)
          )
        )
      ];
    };
}
