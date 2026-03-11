{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.hooks;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.hooks = mkTopSection {
    pre_drain_roles = mkOption {
      description = "Defines the roles which should be executed before draining the Kubernetes node";
      default = [];
      type = with types; listOf nonEmptyStr;
    };
    post_uncordon_roles = mkOption {
      description = ''
        Defines the roles which should be executed after uncordoning the Kubernetes node.

        Custom roles may be placed into ``k8s-custom/roles``.
      '';
      default = [];
      type = with types; listOf nonEmptyStr;
    };
  };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/hooks.yaml";
      ansible_prefix = "hooks_";
    })
  ];
}
