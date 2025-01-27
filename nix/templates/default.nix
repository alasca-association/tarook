{
  inputs,
  lib,
  self,
  flake-parts-lib,
  ...
}: {
  flake = {lib, ...}: {
    templates.cluster-repo = {
      description = ''
        Template containing all the Nix parts of the cluster repo
      '';
      path = ./cluster-repo;
    };
  };
}
