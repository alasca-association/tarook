{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  networking = ((import ./test_networking.nix) {inherit lib ctx;}).passthru.testSuite.units;
  oci = ((import ./test_oci.nix) {inherit lib ctx;}).passthru.testSuite.units;
  version = ((import ./test_version.nix) {inherit lib ctx;}).passthru.testSuite.units;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "helmOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      chartRepoUrl = {
        target = optionTypes.chartRepoUrl;
        # alias type, so no tests are needed
        tests = {};
      };
      chartReleaseName = {
        target = optionTypes.chartReleaseName;
        tests.typeChecking = {
          accepted.inputs = [
            "projectcalico"
            "yaook.cloud"
            "cloud-provider-openstack"
            "1name1"
            "a.name"
            "a"
            "a-name-with-53-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            ""
            "nested/name"
            "name-with-CAPITALS"
            "-name-starting-ending-with-a-dash-"
            ".name-starting-ending-with-a-dot."
            "name-with-double..dots"
            "a-name-with-54-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          inherit nonStringValuesRejected;
        };
      };
      chartVersion = {
        target = optionTypes.chartVersion;
        # chartVersion is a union of semver2VersionStr and oci.imageTag
        tests.typeChecking = {
          semver2Accepted.inputs = version.semver2VersionStr.tests.typeChecking.accepted.inputs;
          imageTagAccepted.inputs = oci.imageTag.tests.typeChecking.accepted.inputs;
          # oci.imageTag is a superset of semver2VersionStr therefore we can simply reuse the value it rejects
          inherit (oci.imageTag.tests.typeChecking) rejected;
          inherit nonStringValuesRejected;
        };
      };
      chartRef = {
        target = optionTypes.chartRef;
        # composite type, so no tests are needed
        tests = {};
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
