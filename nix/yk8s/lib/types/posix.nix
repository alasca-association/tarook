{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    posix1-2024
    ;
in {
  posixPathSegment = mkRegexStrOptionType {
    name = "posixPathSegment";
    description = "POSIX path segment (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };
  posixPathSegmentWithSpecial = mkRegexStrOptionType {
    name = "posixPathSegmentWithSpecial";
    description = "POSIX path segment";
    matchAgainstAllOf = ["^(${posix1-2024.filenameRE})$"];
  };
  posixFilename = mkRegexStrOptionType {
    name = "posixFilename";
    description = "POSIX file name";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };

  relativePosixPath = mkRegexStrOptionType {
    name = "relativePosixPath";
    description = "Relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeNoSpecialRE})$"];
  };
  relativePosixPathWithSpecial = mkRegexStrOptionType {
    name = "relativePosixPathWithSpecial";
    description = "Relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeRE})$"];
  };
  absolutePosixPath = mkRegexStrOptionType {
    name = "absolutePosixPath";
    description = "Absolute POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteNoSpecialRE})$"];
  };
  absolutePosixPathWithSpecial = mkRegexStrOptionType {
    name = "absolutePosixPathWithSpecial";
    description = "Absolute POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteRE})$"];
  };
  posixPath = mkRegexStrOptionType {
    name = "posixPath";
    description = "Absolute or relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyNoSpecialRE})$"];
  };
  posixPathWithSpecial = mkRegexStrOptionType {
    name = "posixPathWithSpecial";
    description = "Absolute or relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyRE})$"];
  };

  posixUserName = mkRegexStrOptionType {
    name = "posixUserName";
    description = "POSIX user name";
    matchAgainstAllOf = ["^(${posix1-2024.usernameRE})$"];
  };
}
