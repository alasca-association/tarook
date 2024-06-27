{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.custom;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.custom = mkOption {
    description = ''
      Since yaook/k8s allows to
      :ref:`execute custom playbook(s) <abstraction-layers.customization>`, the
      following section allows you to specify your own custom variables to be
      used in these.
    '';
    type = types.attrs;
    default = {};
    example = {
      my_custom_section_prefix = {
        my_var = "this produces the var `my_custom_section_prefix_my_var";
      };
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/custom.yaml";
    })
  ];
}
