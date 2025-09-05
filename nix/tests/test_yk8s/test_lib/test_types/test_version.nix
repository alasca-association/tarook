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
      name = "versionOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      semver2VersionStr = {
        target = optionTypes.semver2VersionStr;
        tests.typeChecking = {
          accepted.inputs = [
            "0.0.0"
            "1.0.0"
            "1.0.0-alpha"
            "1.0.0-alpha.1"
            "1.0.0-alpha.11"
            "1.0.0-alpha.beta"
            "1.0.0-rc.1"
            "1.0.0-alpha+001"
            "1.0.0+20130313144700"
            "1.0.0-beta+exp.sha.5114f85"
            "1.0.0+21AF26D3----117B344092BD"
            "1.0.0-0.3.7"
            "1.0.0-x.7.z.92"
            "1.0.0-x-y-z.--"
            "29235.2499243.1358792357"
          ];
          rejected.inputs = [
            ""
            "1"
            "1.0"
            "1.0."
            ".1.0"
            "1.0..0"
            "1.0.0.0"
            "01.0.0" # leading zeros are accepted by semver1 only
            "v1.0.0"
            "1+1.0.0"
            "A.B.C"
            "1A.2B.3C"
            "latest"
            "foo/bar"
            "sha256:10901ccd8d249047f9761845b4594f121edef079cfd8224edebd9ea726f0a7f6"
            "10901ccd"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
