{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  inherit (builtins) hasAttr readDir attrNames;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkContainerSection;
in {
  imports = [
    ./calico.nix
    ./cert-manager.nix
    ./ch-k8s-lbaas.nix
    ./etcd-backup.nix
    ./fluxcd.nix
    ./ingress.nix
    ./ipsec.nix
    ./k8s-local-path-provisioner.nix
    ./k8s-local-storage-controller.nix
    ./monitoring.nix
    ./rook.nix
    ./vault.nix
    ./wireguard
  ];
}
