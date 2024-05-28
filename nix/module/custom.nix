{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.custom;
  inherit (lib) mkOption types;
in {
  # TODO if os.getenv("K8S_CUSTOM_STAGE_USAGE", "true") == "true":

  # TODO import definitions from custom stage dir
  options.yk8s.custom = mkOption {
      description = ''
        Specify variables to be used in the custom stage here. See below for examples.
      '';
      type = types.attrs;
      default = {};
      example = ''
      {
        my_custom_section_prefix = {
          my_var = ""; # produces the var `my_custom_section_prefix_my_var = ""`
        };
      }
      '';
    };
  config.yk8s.custom = {
    _inventory_path = "all/custom.yaml";
  };
}
