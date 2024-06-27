# adapted from https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/modules/misc/assertions.nix
{lib, ...}:
with lib; {
  options.yk8s = {
    assertions = mkOption {
      type = types.listOf types.unspecified;
      internal = true;
      default = [];
      example = [
        {
          assertion = false;
          message = "you can't enable this for that reason";
        }
      ];
      description = ''
        This option allows modules to express conditions that must
        hold for the evaluation of the system configuration to
        succeed, along with associated error messages for the user.
      '';
    };

    warnings = mkOption {
      internal = true;
      default = [];
      type = types.listOf types.str;
      example = ["The `foo' service is deprecated and will go away soon!"];
      description = ''
        This option allows modules to show warnings to users during
        the evaluation of the system configuration.
      '';
    };
  };
}
