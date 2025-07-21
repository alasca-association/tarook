{
  lib,
  pkgs,
  ...
}: let
in {
  checks.default = let
    tests = import ./tests {
      inherit lib;
      importPath = ./.;
    };
  in
    pkgs.runCommandLocal "check" {} (
      if tests
      then "mkdir $out"
      else "false"
    );
}
