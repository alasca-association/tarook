{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.cert-manager;
  inherit (builtins) hasAttr readDir attrNames;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkContainerSection;
in {
  imports = let
    path = ../../k8s-supplements/ansible/roles;
    hasNix = n: hasAttr "default.nix" (readDir "${path}/${n}");
    rolesWithNix = attrNames (filterAttrs (name: type: type == "directory" && hasNix name) (readDir path));
  in
    map (n: "${path}/${n}") rolesWithNix;
  options.yk8s.k8s-service-layer = mkContainerSection {};
}
