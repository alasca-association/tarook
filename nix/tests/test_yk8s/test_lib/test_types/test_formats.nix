{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  inherit
    (common)
    mkPassthruTest
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "formatsOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      jsonValue = {
        target = optionTypes.jsonValue;
        tests.typeChecking = {
          accepted.inputs = [
            null
            false
            1
            1.5
            "a string"
            ["a" "list" 1 1.5 {}]
            {
              an = "attributeset";
              containing = ["a" "list" 1 1.5];
            }
          ];
          rejected.inputs = [
            (x: x)
            ./.
          ];
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
