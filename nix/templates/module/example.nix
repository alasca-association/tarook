{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.example;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.example = mkTopSection {
    _docs.preface = ''
      This text will appear before the listing of the  options in the documentation.
    '';
    enabled = mkEnableOption "example"; # Will be rendered to "Whether to enable example" in the docs

    boolean_option = mkOption {
      description = ''
        Add a description here
      '';
      type = types.bool;
      default = false; # If default value is omitted, the option is mandatory
    };

    optional_option = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "Some value"; # we can also add an example text
    };

    list_option = mkOption {
      description = ''
        This option is a list and is empty by default
      '';
      type = with types; listOf nonEmptyStr;
      default = [];

      # examples should be written such that the example text can be put verbatim behind the = sign
      example = ["some value" "some other value"];
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/example.yaml"; # this is where the values will end up under inventory/group_vars
    })
  ];
}
