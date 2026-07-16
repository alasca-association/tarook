{pkgs, ...}: {
  packages = {
    tarook = pkgs.callPackage ./tarook.nix {};
  };
}
