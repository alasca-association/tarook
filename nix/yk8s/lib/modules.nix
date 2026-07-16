{lib, ...}: let
  yk8s-lib.transform = import ./transform.nix {inherit lib;};
  types = import ./types {inherit lib;};

  inherit
    (lib)
    setAttrByPath
    mkOption
    showOption
    getAttrFromPath
    showFiles
    doRename
    attrByPath
    concatStringsSep
    optional
    ;

  findTopSection = options: path: let
    _findTopSection = options: currentPath: let
      opt = lib.getAttrFromPath (["yk8s"] ++ currentPath) options;
    in
      if opt?"_internal" && opt._internal.sectionType.default == "top"
      then currentPath
      else if currentPath == []
      then path
      else _findTopSection options (lib.init currentPath);
  in
    _findTopSection options path;
in rec {
  /*
     Return a module that causes a warning to be shown if the
     specified option is defined. For example,

     mkRemovedOptionModule ["kubernetes" "use_podsecuritypolicies"] "<replacement instructions>"

     causes a assertion if the user defines kubernetes.use_podsecuritypolicies.

     replacementInstructions is a string that provides instructions on
     how to achieve the same functionality without the removed option,
     or alternatively a reasoning why the functionality is not needed.
     replacementInstructions SHOULD be provided!

  (Adapted from https://github.com/nixos/nixpkgs/blob/master/lib/modules.nix)
  */
  mkRemovedOptionModule = optionPath: replacementInstructions: {options, ...}: let
    absOptionName = ["yk8s"] ++ optionPath;
    section = findTopSection options optionPath;
    option = lib.lists.removePrefix section optionPath;
    isSection = option == [];
    desc =
      if isSection
      then "section"
      else "option";
  in {
    options = setAttrByPath absOptionName (mkOption {
      visible = false;
      apply = x: throw "The ${desc} `${showOption absOptionName}' can no longer be used since it's been removed. ${replacementInstructions}";
    });
    config.yk8s =
      {
        assertions = let
          opt = getAttrFromPath absOptionName options;
        in [
          {
            assertion = !opt.isDefined;
            message = ''
              The ${desc} definition `${showOption absOptionName}' in ${showFiles opt.files} no longer has any effect; please remove it.
              ${replacementInstructions}
            '';
          }
        ];
      }
      // (lib.optionalAttrs (!isSection) (setAttrByPath section {_internal.removedOptions = [option];}));
  };

  /*
  Return a module that causes warnings to be shown if a resource option
  of the form ${prefix}_[memory|cpu]_[request|limit] is used, the defined value
  however forwarded to${prefix}_resources.[memory|cpu].[request|limit].
  For example,

    imports = [
      ....
    ] ++
    (mkRenamedResourceOptionModule ["k8s-service-layer" "rook"] ["mon" "osd" "mgr" "mds" "operator"]);
  */
  mkRenamedResourceOptionModule = section: prefix: {
    imports =
      lib.mapCartesianProduct ({
        prefix,
        res,
        type,
      }: (
        mkRenamedOptionModule (section ++ ["${prefix}_${res}_${type}"]) (section ++ ["${prefix}_resources" "${type}s" "${res}"])
      )) {
        inherit prefix;
        res = ["memory" "cpu"];
        type = ["request" "limit"];
      };
  };

  /*
  Return a module that causes a warning to be shown if the
  specified "fromPath" option is defined; the defined value is however
  forwarded to the "toPath" option. This can be used to rename options
  while providing backward compatibility. For example,

    imports = [
      (mkRenamedOptionModule ["wireguard" "wg_ip_cidr"] ["wireguard" "ip_cidr"])
    ];

  forwards any definitions of wireguard.wg_ip_cidr to
  wireguard.ip_cidr while printing a warning.

  This also copies over the priority from the aliased option to the
  non-aliased option.
  */
  mkRenamedOptionModule = fromPath: toPath: {options, ...}: let
    sectionFrom = findTopSection options fromPath;
    optionFrom = lib.lists.removePrefix sectionFrom fromPath;
    absFrom = ["yk8s"] ++ fromPath;
    absTo = ["yk8s"] ++ toPath;
  in {
    imports = [
      (doRename {
        from = absFrom;
        to = absTo;
        visible = false;
        warn = true;
        use = builtins.trace "Obsolete option `${showOption absFrom}' is used. It was renamed to `${showOption absTo}'.";
      })
      {
        config.yk8s = setAttrByPath sectionFrom {_internal.removedOptions = [optionFrom];};
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
    memoryLimit = attrByPath (absOpt ++ ["limits" "memory"]) null config;
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
      (mkResourceOptionModule ["ch-k8s-lbaas"] ["controller_resources"] {
        description = "Request and limit for the LBaaS controller";
        cpu.request = "100m";
        memory.limit = "256Mi";
      })
    ];
  */
  mkResourceOptionModule = sectionPath: optionPath: {
    description,
    cpu,
    memory,
  }: let
    sec = ["yk8s"] ++ sectionPath;
    opt = optionPath;
    absOpt = sec ++ opt;
  in
    {config, ...}: {
      options = setAttrByPath absOpt (mkOption {
        default = {};
        type = types.submodule {
          options = {
            limits.cpu = mkOption {
              description = ''
                CPU limits should never be set.

                Thus, this option is deprecated.
              '';
              type = with types; nullOr yk8s.k8s.quantity;
              default = cpu.limit or null;
            };
            requests.cpu = mkOption {
              inherit description;
              type = with types; nullOr yk8s.k8s.quantity;
              default = cpu.request or null;
              example = cpu.example or null;
            };

            requests.memory = mkOption {
              description = ''
                Memory requests should always be equal to the limits.

                Thus, this option is deprecated.
              '';
              type = with types; nullOr yk8s.k8s.quantity;
              default = memory.request or (attrByPath (absOpt ++ ["limits" "memory"]) null config);
              defaultText = memory.request or "\${${lib.strings.concatStringsSep "." (["config"] ++ absOpt ++ ["limits" "memory"])}}";
            };
            limits.memory = mkOption {
              inherit description;
              type = with types; nullOr yk8s.k8s.quantity;
              default = memory.limit or null;
              example = memory.example or null;
            };
          };
        };
        apply = yk8s-lib.transform.filterNull;
      });
      config = setAttrByPath (sec ++ ["_internal" "unflat"]) [opt];
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
        (mkMultiResourceOptionsModule ["k8s-service-layer" "rook"] {
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
  mkMultiResourceOptionsModule = sectionPath: {
    description,
    resources,
  }: {
    imports = lib.attrsets.foldlAttrs (acc: prefix: values:
      acc
      ++ [
        (mkResourceOptionModule sectionPath ["${prefix}_resources"] {
          inherit description;
          inherit (values) cpu memory;
        })
      ]) []
    resources;
  };
}
