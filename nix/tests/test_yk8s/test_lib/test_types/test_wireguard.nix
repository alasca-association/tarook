{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  encoding = ((import ./test_encoding.nix) {inherit lib ctx;}).passthru.testSuite.units;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "wireguardOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      key = {
        target = optionTypes.key;
        tests.typeChecking = {
          accepted.inputs = [
            "AELw/sSLVdd+V1A8sVDyA2nHk8nJXCYgKLwlPvQKuGo="
            "eDaj+ysRCXFNYfoHZL58VRr+tSfRQVj6L+mfwJrOGH4="
            "aBWORk469SnonqPSO31ZTo3EDCtmcZPs1AOsjYQTdE0="
            "EPtKEwRYflRsrqMHURfpRz38Gl+KebY0rUKaVjOCC0w="
          ];
          rejected.inputs =
            [
              ""
              "VGFyb29r"
              "AELw/sSLVdd+valid+base64+but+48+chars+aamx1Aad3f"
              "nxq7+base64+but+40+chars+8mrz09dxnq84y1a"
            ]
            # key is a subset of base64Str
            ++ encoding.base64Str.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
