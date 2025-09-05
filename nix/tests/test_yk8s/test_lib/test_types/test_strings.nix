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
      name = "stringsOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
    };
  };
in
  mkPassthruTest optionTypeUnitTests
