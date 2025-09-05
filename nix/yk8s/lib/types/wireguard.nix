{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    rfc4648
    ;
in {
  key = mkRegexStrOptionType {
    name = "wireguardKey";
    description = "Wireguard key";
    matchAgainstAllOf = [
      "^(${rfc4648.base64StrRE})$"

      # length=44 (WORKAROUND: This should have been encoded in base64StrRE with positive lookaheads but these are unsupported)
      "^.{44}$"
    ];
  };
}
