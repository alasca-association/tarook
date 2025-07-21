{
  lib,
  yk8s-test-lib,
  ctx,
  ...
}: let
  pkgs = import <nixpkgs> {};
in
  with ctx;
    evaluator {
      self = evaluator;
      yk8s-test-lib = yk8s-test-lib;
      path = ./.;
      importPath = importPath;
    }
