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
      name = "unitsOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      bytesPower2 = {
        target = optionTypes.bytesPower2;
        tests.typeChecking = {
          accepted.inputs = [
            "512KiB"
            "445MiB"
            "50GiB"
            "2TiB"
            "5.6GiB"
            "0.25TiB"
            "4.674GiB"
            "4.6745GiB"
          ];
          rejected.inputs =
            [
              ""
              "512kiB"
              "512KB"
              "50GB"
              ".34MiB"
              "5.6G"
              "500M"
              "50"
              "4.67"
              "4.674"
              "4.6745"
              50
              4.67
            ]
            # bytesPower2 is mutually exclusive with bytesPower10
            ++ bytesPower10.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      bytesPower10 = {
        target = optionTypes.bytesPower10;
        tests.typeChecking = {
          accepted.inputs = [
            "512kB"
            "445MB"
            "50GB"
            "2TB"
            "5.6GB"
            "0.25TB"
            "4.674GB"
            "4.6745GB"
          ];
          rejected.inputs =
            [
              ""
              "512KiB"
              "50GiB"
              ".34MB"
              "50"
              "4.67"
              "4.674"
              "4.6745"
              50
              4.67
            ]
            # bytesPower10 is mutually exclusive with bytesPower2
            ++ bytesPower2.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
