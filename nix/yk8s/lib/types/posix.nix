{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    posix1-2024
    ;
in {
  pathSegment = mkRegexStrOptionType {
    name = "posixPathSegment";
    description = "POSIX path segment (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };
  pathSegmentWithSpecial = mkRegexStrOptionType {
    name = "posixPathSegmentWithSpecial";
    description = "POSIX path segment";
    matchAgainstAllOf = ["^(${posix1-2024.filenameRE})$"];
  };
  filename = mkRegexStrOptionType {
    name = "posixFilename";
    description = "POSIX file name";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };

  relativePath = mkRegexStrOptionType {
    name = "relativePosixPath";
    description = "Relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeNoSpecialRE})$"];
  };
  relativePathWithSpecial = mkRegexStrOptionType {
    name = "relativePosixPathWithSpecial";
    description = "Relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeRE})$"];
  };
  absolutePath = mkRegexStrOptionType {
    name = "absolutePosixPath";
    description = "Absolute POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteNoSpecialRE})$"];
  };
  absolutePathWithSpecial = mkRegexStrOptionType {
    name = "absolutePosixPathWithSpecial";
    description = "Absolute POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteRE})$"];
  };
  path = mkRegexStrOptionType {
    name = "posixPath";
    description = "Absolute or relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyNoSpecialRE})$"];
  };
  pathWithSpecial = mkRegexStrOptionType {
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
