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
  Return an attributeset where all nested attributes are flattened. The name of the path will be separated by "_"
  Optionally pass a list of option paths that should not be flattened.

  Example:
  flatten {except = [["a" "d"] ["x"]];} {a.b.c = 1; a.d.e = 2; x.y = 3;}
  -> {a_b_c = 1; a_d = {e = 2;}; x = {y = 3;};}

  Optionally pass a depth until which the nesting should be flattened.
  Attention: Nestings that do not exceed the specified depth and end with an empty attribute set will disappear

  Example:
  flatten {depth=1;} { a.b.c = 1; a.d = 2; }
  -> { a_b = {c = 1;}; a_d = 2; }
  flatten {depth=2;} { a.b.c = 1; a.d = {}; }
  -> { a_b_c = 1; }

  */
  flatten = {
    except ? [],
    depth ? null,
  }: let
    inherit (builtins) isAttrs elem head tail foldl' filter;
    inherit (lib.attrsets) foldlAttrs mapAttrs';
    exceptCurrentLevel = map head (filter (e: (builtins.length e) == 1) except);
    exceptNextLevel = outerName:
      foldl' (acc: e:
        acc
        ++ (
          lib.optional ((head e) == outerName)
          (tail e)
        )) [];
  in
    foldlAttrs (
      acc: outerName: outerValue:
        acc
        // (
          if
            (depth != null -> depth > 0)
            && isAttrs outerValue
            && ! elem outerName exceptCurrentLevel
          then
            mapAttrs' (name: value: {
              name = "${outerName}_${name}";
              inherit value;
            }) (flatten {
                except = exceptNextLevel outerName except;
                depth =
                  if depth == null
                  then null
                  else depth - 1;
              }
              outerValue)
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

  /*
  Return whether a regular expression is matched by a given string

  Arguments:
  - regex: The regular expression
  - str: A string

  Example:
    matchesRegex "foo.*" "foobar" -> true
    matchesRegex "[0-9]+" "foobar" -> false
  */
  matchesRegex = regex: str: (builtins.match regex str) != null;

  /*
  Filter out items of certain types from a list

  Returns the items that are not ignored and prints the ignored ones.

  Arguments:
  - messagePrefix: A string to prefix the message of ignored items with
  - ignoredTypes: A list of item types that shall be ignored
  - items: A list of items
  */
  ignoreItemsOfTypeWithMsg = messagePrefix: ignoredTypes: items: let
    partitioned =
      lib.lists.partition (
        item: ! (lib.lists.any (type: type.check item) ignoredTypes)
      )
      items;
  in
    if (builtins.length partitioned.wrong) == 0
    then partitioned.right
    else
      builtins.trace
      "${messagePrefix}Ignoring inapplicable items ${builtins.concatStringsSep ", " partitioned.wrong}"
      partitioned.right;

  /*
  Filter out items of the disabled IP family from a list

  Returns the items that are not ignored and prints the ignored ones.

  Arguments:
  - <customize>: An attribute set that specifies the `ipv4Types` and `ipv6Types`
                 and whether `ipv4Enabled` and `ipv6Enabled`
  - msgPrefix: A string to prefix the message of ignored items with
  - *: A list of items
  */
  ignoreItemsOfDisabledIPFamily = {
    ipv4Types ? [],
    ipv6Types ? [],
    ipv4Enabled ? false,
    ipv6Enabled ? false,
  }: msgPrefix: let
    ignoredTypes =
      builtins.foldl'
      (acc: x:
        acc
        ++ (
          if x.ignoreIf
          then x.types
          else []
        ))
      [] [
        {
          types = ipv4Types;
          ignoreIf = ! ipv4Enabled;
        }
        {
          types = ipv6Types;
          ignoreIf = ! ipv6Enabled;
        }
      ];
  in
    ignoreItemsOfTypeWithMsg msgPrefix ignoredTypes;

  /*
  Output a warning when the given value is zero

  Arguments:
    - message: Warning message to output
    - *: Integer value to check
  */
  warnIfZero = message: value: lib.trivial.warnIf (value == 0) message value;

  /*
  Output a warning for selected items of an attrset if their value is zero

  Arguments:
    - mkMessage: A function that takes the current attr name and produces the warning message to output
    - *: Attrset to check
  */
  warnIfAttrZero = mkMessage: names:
    lib.attrsets.mapAttrs (
      name: value:
        if builtins.elem name names
        then warnIfZero (mkMessage name) value
        else value
    );
}
