{lib, ...}:
with lib; rec {
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
  Return a module that causes a warning to be shown if the
  specified "from" option is defined; the defined value is however
  forwarded to the "to" option. This can be used to rename options
  while providing backward compatibility. For example,

    mkRenamedOptionModule "wireguard" "wg_ip_cidr" "ip_cidr")

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

    mkRenamedOptionModule "wireguard" "wg_ip_cidr" "ip_cidr")

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
    ];
  };
}
