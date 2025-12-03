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
      name = "openstackOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = {
      availabilityZoneName = {
        target = optionTypes.availabilityZoneName;
        tests.typeChecking = {
          accepted.inputs = [
            "AZ1"
            "1AZ"
            "az with spaces"
            "az:foo"
            "@az1"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      swiftContainerName = {
        target = optionTypes.swiftContainerName;
        tests.typeChecking = {
          accepted.inputs = [
            "a"
            "foo3"
            "6bar"
            "some-container"
            "container name with spaces"
            "-name-with-leading-dash"
            "CAPITAL_NAME"
            "container-name-with-256-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            ""
            "www/pages"
            "container-name-with-257-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          inherit nonStringValuesRejected;
        };
      };
      flavorName = {
        target = optionTypes.flavorName;
        tests.typeChecking = {
          accepted.inputs = [
            "flavor1"
            "1flavor"
            "flavor with spaces"
            "flavor:foo"
            "@flavor"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      imageName = {
        target = optionTypes.imageName;
        tests.typeChecking = {
          accepted.inputs = [
            "image1"
            "1image"
            "image with spaces"
            "image:foo"
            "@image"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      keypairName = {
        target = optionTypes.keypairName;
        tests.typeChecking = {
          accepted.inputs = [
            "keypair1"
            "1keypair"
            "keypair with spaces"
            "keypair:foo"
            "@keypair"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      networkName = {
        target = optionTypes.networkName;
        tests.typeChecking = {
          accepted.inputs = [
            "network1"
            "1network"
            "network with spaces"
            "network:foo"
            "@network"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      serverGroupName = {
        target = optionTypes.serverGroupName;
        tests.typeChecking = {
          accepted.inputs = [
            "servergroup1"
            "1servergroup"
            "servergroup with spaces"
            "servergroup:foo"
            "@servergroup"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
      volumeTypeName = {
        target = optionTypes.volumeTypeName;
        tests.typeChecking = {
          accepted.inputs = [
            "volume1"
            "1volume"
            "volume with spaces"
            "volume:foo"
            "@volume"
          ];
          rejected.inputs = [
            ""
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
