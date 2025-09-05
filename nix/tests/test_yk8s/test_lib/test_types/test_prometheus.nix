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
    nonAttrsValuesRejected
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "prometheusOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      intervalStr = {
        target = optionTypes.intervalStr;
        tests.typeChecking = {
          accepted.inputs = [
            ""
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms"
            "8d5h"
            "19272936413s"
            "01s"
          ];
          rejected.inputs = [
            "45mm"
            "12"
            "-5m"
            "m"
            "45m34h55s" # not in order
            "33ns"
          ];
          inherit nonStringValuesRejected;
        };
      };
      labelName = {
        target = optionTypes.labelName;
        tests.typeChecking = {
          accepted.inputs = [
            "a"
            "foobar"
            "FOObar"
            "1label1"
            "__name__"
            "__tmp"
            "__scrape_interval__"
          ];
          rejected.inputs = [
            ""
            " "
            "label_with_special!_char"
            "label with spaces-and-dashes"
          ];
          inherit nonStringValuesRejected;
        };
      };
      timeoutStr = {
        target = optionTypes.timeoutStr;
        tests.typeChecking = {
          accepted.inputs = [
            ""
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms"
            "8d5h"
            "19272936413s"
            "01s"
          ];
          rejected.inputs = [
            "45mm"
            "12"
            "-5m"
            "m"
            "45m34h55s" # not in order
            "33ns"
          ];
          inherit nonStringValuesRejected;
        };
      };
      relabelConfig = {
        target = optionTypes.relabelConfig;
        tests.typeChecking = {
          accepted.inputs = [
            {
              sourceLabels = ["foo" "bar"];
              targetLabel = "baz";
            }
            {
              action = "Replace";
              arbitaryKey = null;
            }
            {
              sourceLabels = [];
              separator = ",";
              targetLabel = "foo";
              regex = "bar";
              modulus = 4;
              replacement = "baz";
              action = "Replace";
            }
          ];
          rejected.inputs = [
            {
              sourceLabels = "string";
              separator = 1;
              targetLabel = "";
              regex = "";
              modulus = -4;
              replacement = "";
              action = "";
            }
          ];
          inherit nonAttrsValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
