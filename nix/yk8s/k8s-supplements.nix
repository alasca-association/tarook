{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.cert-manager;
  inherit (builtins) hasAttr readDir attrNames;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkContainerSection;
in {
  imports = let
    root = ../..;
    path = "${root}/k8s-supplements/ansible/roles";
    hasNix = n: hasAttr "default.nix" (readDir "${path}/${n}");
    rolesWithNix = attrNames (filterAttrs (name: type: type == "directory" && hasNix name) (readDir path));
  in
    map (n: "${path}/${n}") rolesWithNix;
}
