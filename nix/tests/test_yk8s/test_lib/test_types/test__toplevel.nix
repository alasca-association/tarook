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
    reusableValues
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "toplevelOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      attrsOf' = {
        target = optionTypes.attrsOf';
        tests.typeChecking = {
          oneCheckedItemContainedAccepted = {
            params = [
              {a = lib.types.nonEmptyStr;}
            ];
            inputs = [
              {a = "foo";}
              {
                a = "foo";
                b = 1;
              }
            ];
          };
          threeCheckedItemsContainedAccepted = {
            params = [
              {
                a = lib.types.nonEmptyStr;
                b = lib.types.int;
                c = lib.types.attrs;
              }
            ];
            inputs = [
              {
                a = "foo";
                b = 1;
                c = {};
              }
              {
                a = "foo";
                b = 1;
                c = {};
                d = null;
              }
            ];
          };
          noCheckedItemContainedAccepted = {
            params = [
              {a = lib.types.nonEmptyStr;}
            ];
            inputs = [
              {}
              {b = 1;}
              {
                b = 2;
                c = "";
              }
            ];
          };
          checkedInvalidItemContainedRejected = {
            params = [
              {
                a = lib.types.nonEmptyStr;
                b = lib.types.int;
                c = lib.types.attrs;
              }
            ];
            inputs = [
              {
                a = "";
                b = 1;
                c = {};
                d = "any";
              }
              {
                a = "";
                b = null;
                c = {};
                d = "any";
              }
              {
                a = "";
                b = null;
                c = 7;
                d = "any";
              }
              {
                a = "";
                b = 1;
                d = "any";
              }
              {c = 7;}
            ];
          };
          nonAttrsValuesRejected = {
            params = [{}];
            inputs = reusableValues.nonAttrs;
          };
        };
      };

      withLimitedLength = {
        target = optionTypes.withLimitedLength;
        tests.description = {
          minLengthString = {
            params = [
              {min = 5;}
              lib.types.str
            ];
            text = "string with at least 5 characters";
          };
          maxLengthString = {
            params = [
              {max = 32;}
              lib.types.str
            ];
            text = "string with up to 32 characters";
          };
          minMaxLengthString = {
            params = [
              {
                min = 2;
                max = 10;
              }
              lib.types.str
            ];
            text = "string with 2 to 10 characters";
          };
          exactLengthString = {
            params = [
              rec {
                min = 42;
                max = min;
              }
              lib.types.str
            ];
            text = "string with exactly 42 characters";
          };
        };
        tests.typeChecking = {
          lessThanFiveCharsRejected = {
            params = [
              {min = 5;}
              lib.types.str
            ];
            inputs = [
              "four"
            ];
          };
          fiveAndMoreCharsAccepted = {
            params = [
              {min = 5;}
              lib.types.str
            ];
            inputs = [
              "five5"
              "sixSIX"
            ];
          };
          twelveAndLessCharsAccepted = {
            params = [
              {max = 12;}
              lib.types.str
            ];
            inputs = [
              "sixSIX"
              "twelve chars"
            ];
          };
          moreThanTwelveCharsRejected = {
            params = [
              {max = 12;}
              lib.types.str
            ];
            inputs = [
              "longer than 12 characters"
            ];
          };
          fourToTwelveCharsAccepted = {
            params = [
              {
                min = 4;
                max = 12;
              }
              lib.types.str
            ];
            inputs = [
              "four"
              "sixSIX"
              "twelve chars"
            ];
          };
          lessThanFourAndMoreThanTwelveCharsRejected = {
            params = [
              {
                min = 4;
                max = 12;
              }
              lib.types.str
            ];
            inputs = [
              "foo"
              "longer than 12 characters"
            ];
          };
          extremelyArbitaryInputAccepted = {
            params = [
              {
                min = 0;
                max = 19244;
              }
              lib.types.str
            ];
            inputs = [
              ":% )ydd DC1!4c-s_sd4 ~*#"
            ];
          };
          nonStringValuesRejected = {
            params = [
              {min = 0;}
              lib.types.str
            ];
            inputs = reusableValues.nonString;
          };
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
