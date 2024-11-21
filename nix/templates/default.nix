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
    templates.migration = {
      description = ''
        Template to migrate from before vX.0.0
      '';
      path = ./migration;
    };
  };
}
