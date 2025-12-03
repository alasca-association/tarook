{lib}: let
  transform = import ./../transform.nix {inherit lib;};
  inherit (transform) matchesRegex;
in rec {
  /*
  Create an option type that matches a given string value against a set of regular expressions

  Arguments (as attrset):
  - name: Name of the option type
  - description: Description of the option type
  - matchAgainstAllOf: Optional list of regular expressions of which all must match
  - matchAgainstNoneOf: Optional list of regular expressions of which none must match
  */
  _mkRegexStrOptionType = {
    name,
    description,
    matchAgainstAllOf ? [],
    matchAgainstNoneOf ? [],
  }:
    assert lib.assertMsg
    (!(matchAgainstAllOf == matchAgainstNoneOf))
    "positive and negative regex sets must no be equal";
      lib.mkOptionType {
        name = name;
        description = description;
        descriptionClass = "noun";
        check = x:
          builtins.isString x
          && (
            builtins.all (
              regex: matchesRegex regex x
            )
            matchAgainstAllOf
          )
          && (
            builtins.all (
              regex: builtins.match regex x == null
            )
            matchAgainstNoneOf
          );
      };

  _nonEmptyNonSpacedStr = _mkRegexStrOptionType {
    name = "_nonEmptyNonSpacedStr";
    description = "${lib.types.nonEmptyStr.description} without spaces";
    matchAgainstAllOf = ["^[^ ]+$"];
  };
}
