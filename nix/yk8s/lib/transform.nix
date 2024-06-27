{lib}: rec {
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

  filterInternal = lib.attrsets.filterAttrsRecursive (n: _: n != "_internal");
  filterNull = lib.attrsets.filterAttrsRecursive (_: v: v != null);
  flatten = {except}: let
    inherit (builtins) isAttrs elem;
    inherit (lib.attrsets) foldlAttrs mapAttrs';
  in
    foldlAttrs (
      acc: outerName: outerValue:
        acc
        // (
          if isAttrs outerValue && ! elem outerName except
          then
            mapAttrs' (name: value: {
              name = "${outerName}_${name}";
              inherit value;
            }) (flatten {inherit except;} outerValue)
          else {"${outerName}" = outerValue;}
        )
    ) {};
  onlyIfEnabled = cfg:
    if ! cfg.enabled
    then {enabled = false;}
    else cfg;
  addPrefix = prefix:
    lib.attrsets.mapAttrs' (name: value: {
      name = "${prefix}${name}";
      inherit value;
    });
}
