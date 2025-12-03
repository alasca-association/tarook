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
      name = "encodingOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      base64Str = {
        target = optionTypes.base64Str;
        tests.typeChecking = {
          accepted.inputs = [
            "6BK8itgi30zEqwe3RpPnRje0nkB8OJ3+lOxsUmfzqnA="
            "VGFyb29r"
            "eWFvb2s="
            "8J+aoiBGdWxsIGxpZmUtY3ljbGUgbWFuYWdlbWVudCBvZiBLdWJlcm5ldGVzIGNsdXN0ZXJzIHJ1bm5pbmcgb24gYmFyZSBtZXRhbCBvciBPcGVuU3RhY2su"
            "IA=="
          ];
          rejected.inputs = [
            ""
            "IA="
            "4rdHFh%2BHYoS8oLdVvbUzEVqB8Lvm7kSPnuwF0AAABYQ%3D"
            "++"
            "VGFyb29r=="
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
