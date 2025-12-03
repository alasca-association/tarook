{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  networking = ((import ./test_networking.nix) {inherit lib ctx;}).passthru.testSuite.units;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "s3OptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      bucketName = {
        target = optionTypes.bucketName;
        tests.typeChecking = {
          accepted.inputs = [
            "bucket"
            "etcd-backup"
            "example.com"
            "www.example.com"
            "my.example.s3.bucket"
            "bucket-a1b2c3d4-5678-90ab-cdef-example11111"
            "abbb-bucket-name-with-63-characters-bbbbbbbbbbbbbbbbbbbbbbbbbba"
          ];
          rejected.inputs =
            [
              ""
              # from https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html#bucket-names
              "amzn_s3_demo_bucket" # contains underscores
              "AmznS3DemoBucket" # contains uppercase letters
              "amzn-s3-demo-bucket-" # ends with a hyphen
              "example..com" # contains two periods in a row
              "xn--kxae4bafwg.xn--pxaix.example.com" # contains punycode
              "BUCKET"
              "abbb-bucket-name-with-64-characters-bbbbbbbbbbbbbbbbbbbbbbbbbbba"
              "-bucket-"
              ".bucket."
            ]
            # matches format of an IP address
            ++ networking.ipv4Addr.tests.typeChecking.accepted.inputs
            ++ networking.ipv6Addr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      bucketNamePrefix = {
        target = optionTypes.bucketNamePrefix;
        tests.typeChecking = {
          # bucketNamePrefix is a superset of bucketName with length<63
          accepted.inputs = with builtins;
            filter (x: (stringLength x) < 63) bucketName.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              # from https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html#bucket-names
              "amzn_s3_demo_bucket" # contains underscores
              "AmznS3DemoBucket" # contains uppercase letters
              "example..com" # contains two periods in a row
              "xn--kxae4bafwg.xn--pxaix.example.com" # contains punycode
              "BUCKET"
              "abbb-bucket-prefix-with-63-characters-bbbbbbbbbbbbbbbbbbbbbbbbba"
              "-bucket"
              ".bucket"
            ]
            # matches format of an IP address
            ++ networking.ipv4Addr.tests.typeChecking.accepted.inputs
            ++ networking.ipv6Addr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
