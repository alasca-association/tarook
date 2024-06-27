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

  /*
  Remove the attribute "_internal" (and all its children) from attributeset
  */
  filterInternal = lib.attrsets.filterAttrsRecursive (n: _: n != "_internal");

  /*
  Recursively remove all attribute with value null from attributeset, even inside lists
  */
  filterNull = lib.attrsets.foldlAttrs (acc: n: v:
    acc
    // (
      if v == null
      then {}
      else if builtins.isAttrs v
      then {${n} = filterNull v;}
      else if builtins.isList v
      then {
        ${n} =
          map (
            e:
              if builtins.isAttrs e
              then filterNull e
              else e
          )
          v;
      }
      else {${n} = v;}
    )) {};

  /*
  Return an attributeset where all nested attributes are flattened. The name of the path will be separated by "-"
  It is possible to pass attribute names that should not be flattened. Example:

  Example:
  flatten {["d"]} {a.b.c = 1; a.d = 2; }
  -> {a_b_c = 1; a.d = 2;}

  */
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

  /*
  Return the attributeset unchanged if its attribute `enabled` is `true`, else return an empty attributeset.
  */
  onlyIfEnabled = cfg:
    if ! cfg.enabled
    then {enabled = false;}
    else cfg;

  /*
  Return an attribute set that has each attribute name prefixed with a string
  */
  addPrefix = prefix:
    lib.attrsets.mapAttrs' (name: value: {
      name = "${prefix}${name}";
      inherit value;
    });
}
