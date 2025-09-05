{lib}: {
  _regexes = {
    # as per Golang documentation
    golang = let
      # https://pkg.go.dev/tie#ParseDuration
      parseDuration.unsignedRE = "((0|[1-9][0-9]*)(ns|µs|us|ms|s|m|h))+";
    in {
      unsignedIntDurationStrRE = parseDuration.unsignedRE;
    };
  };
  /*
  Variant of nixpkgs.lib.types.attrsOf

  An attribute set of where the values are of the type specified for their respective names in `ts`.

  Example:
    (attrsOf' {a = nonEmptyStr;}).check {a = "foo"; b = 1;} -> true
    (attrsOf' {a = nonEmptyStr;}).check {a = ""; b = 1;} -> false
    (attrsOf' {a = nonEmptyStr;}).check {b = 1;} -> true
  */
  attrsOf' = ts:
    lib.mkOptionType {
      name = "attrsOf'";
      description = "attribute set with items of specific types (${
        builtins.concatStringsSep ", " (
          lib.attrsets.foldlAttrs (acc: n: v: acc ++ ["${n}: ${v.name}"]) [] ts
        )
      })";
      check = x:
        lib.types.attrs.check x
        && lib.attrsets.foldlAttrs
        (
          acc: n: v:
            acc
            && (
              if (builtins.hasAttr n ts)
              then (builtins.getAttr n ts).check v
              else true
            )
        )
        true
        x;
      nestedTypes.elemType = lib.attrsets.attrValues ts;
      inherit (lib.types.attrs) merge emptyValue;
    };

  /*
  Composite type to constrain the input length of string/list option types

  Example:
    withLimitedLength {max = 32;} lib.types.str -> <option type that accepts strings with up to 32 characters>
  */
  withLimitedLength = {
    min ? null,
    max ? null,
  }:
    assert lib.assertMsg
    (!(min == null && max == null))
    "withLimitedLength: min and max must not both be null";
    assert lib.assertMsg
    ((min == null || max == null) || (min <= max))
    "withLimitedLength: min must be smaller than max";
      elemType:
        assert lib.assertMsg
        (elemType.descriptionClass == "noun")
        "withLimitedLength can only be used with noun class option types";
          lib.mkOptionType {
            name = "${elemType.name}WithLimitedLength";
            description = "${elemType.description} with ${
              if (min == null || max == null)
              then
                if min != null
                then "at least ${builtins.toString min}"
                else "up to ${builtins.toString max}"
              else if (min == max)
              then "exactly ${builtins.toString min}"
              else "${builtins.toString min} to ${builtins.toString max}"
            } characters";
            descriptionClass = "composite";
            check = x:
              elemType.check x
              && (
                let
                  type_ = builtins.typeOf x;
                  length =
                    if type_ == "string"
                    then builtins.stringLength x
                    else if type_ == "list"
                    then builtins.length x
                    else throw "withLimitedLength can only be used with string/list option types";
                in
                  (
                    if min != null
                    then length >= min
                    else true
                  )
                  && (
                    if max != null
                    then length <= max
                    else true
                  )
              );
          };
}
