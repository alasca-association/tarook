{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    golang
    ;
in {
  # as per https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
  terraformDurationStr = mkRegexStrOptionType {
    name = "terraformDurationStr";
    description = "Terraform duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };
}
