{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s.networking._regexes)
    rfc4648
    ;
in {
  key = _mkRegexStrOptionType {
    name = "wireguardKey";
    description = "Wireguard key";
    matchAgainstAllOf = [
      "^(${rfc4648.base64StrRE})$"

      # length=44 (WORKAROUND: This should have been encoded in base64StrRE with positive lookaheads but these are unsupported)
      "^.{44}$"
    ];
  };
}
