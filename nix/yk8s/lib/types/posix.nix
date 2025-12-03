{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;

  inherit
    (types.yk8s.posix._regexes)
    posix1-2024
    ;
in {
  _regexes = {
    # as per POSIX.1-2024
    posix1-2024 = {
      # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_146
      filenameRE = "[^/]+";
      # NOTE: A positive lookahead would make this more readable but that is unsupported: "(?!^[.]{1,2})([^/]+)"
      filenameNoSpecialRE = "([^./]{1,2}|[^/]{3,})";

      # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_254
      pathname = let
        sepRE = "[/]+";
        inherit (posix1-2024) filenameRE filenameNoSpecialRE;
        inherit (posix1-2024.pathname) relativeRE relativeNoSpecialRE;
      in {
        relativeRE = "(${filenameRE})((${sepRE})(${filenameRE}))*(${sepRE})?";
        relativeNoSpecialRE = "(${filenameNoSpecialRE})((${sepRE})(${filenameNoSpecialRE}))*(${sepRE})?";
        absoluteRE = "(${sepRE})(${relativeRE})";
        absoluteNoSpecialRE = "(${sepRE})(${relativeNoSpecialRE})";
        anyRE = "(${sepRE})?(${relativeRE})";
        anyNoSpecialRE = "(${sepRE})?(${relativeNoSpecialRE})";
      };

      # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_409
      usernameRE = "[A-Za-z0-9._-]+";
    };
  };
  pathSegment = _mkRegexStrOptionType {
    name = "posixPathSegment";
    description = "POSIX path segment (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };
  pathSegmentWithSpecial = _mkRegexStrOptionType {
    name = "posixPathSegmentWithSpecial";
    description = "POSIX path segment";
    matchAgainstAllOf = ["^(${posix1-2024.filenameRE})$"];
  };
  filename = _mkRegexStrOptionType {
    name = "posixFilename";
    description = "POSIX file name";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };

  relativePath = _mkRegexStrOptionType {
    name = "relativePosixPath";
    description = "Relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeNoSpecialRE})$"];
  };
  relativePathWithSpecial = _mkRegexStrOptionType {
    name = "relativePosixPathWithSpecial";
    description = "Relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeRE})$"];
  };
  absolutePath = _mkRegexStrOptionType {
    name = "absolutePosixPath";
    description = "Absolute POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteNoSpecialRE})$"];
  };
  absolutePathWithSpecial = _mkRegexStrOptionType {
    name = "absolutePosixPathWithSpecial";
    description = "Absolute POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteRE})$"];
  };
  path = _mkRegexStrOptionType {
    name = "posixPath";
    description = "Absolute or relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyNoSpecialRE})$"];
  };
  pathWithSpecial = _mkRegexStrOptionType {
    name = "posixPathWithSpecial";
    description = "Absolute or relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyRE})$"];
  };

  userName = _mkRegexStrOptionType {
    name = "posixUserName";
    description = "POSIX user name";
    matchAgainstAllOf = ["^(${posix1-2024.usernameRE})$"];
  };
}
