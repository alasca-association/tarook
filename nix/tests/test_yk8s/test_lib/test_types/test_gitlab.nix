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
      name = "gitlabOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      projectId = {
        target = optionTypes.projectId;
        tests.typeChecking = {
          accepted.inputs = [
            0
            29738620
            "yaook%2fk8s"
            "yaook%2Fk8s"
          ];
          rejected.inputs = [
            ""
            "yaook/k8s"
          ];
          nonStringValuesRejected.inputs = reusableValues.nonStringInteger;
        };
      };
      terraformStateName = {
        target = optionTypes.terraformStateName;
        tests.typeChecking = {
          accepted.inputs = [
            "tf-state-yk8s"
            "tf-state:current"
            "yaook%2fk8s%2Ftfstate"
          ];
          rejected.inputs = [
            ""
            "tf state"
            "yaook/k8s/tfstate"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
