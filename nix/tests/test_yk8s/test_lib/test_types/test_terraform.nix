{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "terraformOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      durationStr = {
        target = optionTypes.durationStr;
        tests.typeChecking = {
          accepted.inputs = [
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms3ns"
            "45m34h55s"
            "40h7s"
            "19272936413s"
          ];
          rejected.inputs = [
            ""
            "12"
            "01s"
            "45mm"
            "-5m"
            "m"
            "8d5h"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
