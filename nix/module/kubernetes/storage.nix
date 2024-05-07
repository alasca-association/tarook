{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) logIf;
in {
  options.yk8s.kubernetes.storage = {
    rook_enabled = mkEnableOption ''
      Many clusters will want to use rook, so you should enable
      or disable it here if you want. It requires extra options
      which need to be chosen with care.
    '';
    nodeplugin_toleration = mkEnableOption ''
      Setting this to true will cause the storage plugins
      to run on all nodes (ignoring all taints). This is often desirable.
    '';

    cinder_enable_topology = mkOption {
      description = ''
        This flag enables the topology feature gate of the cinder controller plugin.
        Its purpose is to allocate volumes from cinder which are in the same AZ as
        the worker node to which the volume should be attached.
        Important: Cinder must support AZs and the AZs must match the AZs used by nova!
      '';
      type = types.bool;
      default = true; # TODO conflicting value: ansible role had  false
    };
  };
}
