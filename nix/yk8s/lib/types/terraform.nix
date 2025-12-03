{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;

  inherit (types.yk8s._regexes) golang;
in {
  # as per https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
  durationStr = _mkRegexStrOptionType {
    name = "terraformDurationStr";
    description = "Terraform duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };
}
