{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s.version._regexes)
    semver
    ;
in {
  _regexes = {
    # as per Semantic Versioning 2.0.0
    semver = {
      v2 = let
        # https://semver.org/spec/v2.0.0.html#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
        versionStrRE = lib.concatStrings [
          "(0|[1-9][0-9]*)" # major
          "[.]"
          "(0|[1-9][0-9]*)" # minor
          "[.]"
          "(0|[1-9][0-9]*)" # patch
          # optional pre-release
          "(-("
          "(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)"
          "([.](0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*"
          "))?"
          # build metadata
          "([+]([0-9a-zA-Z-]+([.][0-9a-zA-Z-]+)*))?"
        ];
      in {
        inherit versionStrRE;
      };
    };
  };

  semver2VersionStr = _mkRegexStrOptionType {
    name = "semver2VersionStr";
    description = "Semantic version 2 string";
    matchAgainstAllOf = ["^(${semver.v2.versionStrRE})$"];
  };
}
