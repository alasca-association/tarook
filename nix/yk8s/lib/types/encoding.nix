{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
in rec {
  _regexes = {
    # as per IETF RFC 4648
    rfc4648 = let
      # Section 4
      B64CHAR = "[a-z0-9A-Z+/]";
      base64StrRE = "(${B64CHAR}{4})*(${B64CHAR})((${B64CHAR})==|(${B64CHAR}){2}=|(${B64CHAR}){3})";
    in {
      inherit base64StrRE;
    };
  };
  base64Str = _mkRegexStrOptionType {
    name = "base64Str";
    description = "Base64 encoded string";
    matchAgainstAllOf = ["^(${_regexes.rfc4648.base64StrRE})$"];
  };
}
