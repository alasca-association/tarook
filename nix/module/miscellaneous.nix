{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.miscellaneous;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.miscellaneous = mkTopSection {
    wireguard_on_workers = mkEnableOption ''
      Install wireguard on all workers (without setting up any server-side stuff)
      so that it can be used from within Pods.
    '';
  };
  config.yk8s.miscellaneous = {
    _inventory_path = "all/miscellaneous.yaml";
  };
}
