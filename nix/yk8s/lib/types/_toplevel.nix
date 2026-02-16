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
          elemType
          // {
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
                  length_ =
                    if lib.isString x
                    then builtins.stringLength x
                    else if lib.isList x
                    then builtins.length x
                    else throw "withLimitedLength can only be used with string/list option types";
                in
                  (
                    if min != null
                    then length_ >= min
                    else true
                  )
                  && (
                    if max != null
                    then length_ <= max
                    else true
                  )
              );
          };
}
