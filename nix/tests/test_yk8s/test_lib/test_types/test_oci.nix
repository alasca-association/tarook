{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  inherit (lib) mapCartesianProduct filter;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    yk8s-lib
    ;
  inherit
    (yk8s-lib.transform)
    matchesRegex
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "ociOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      imageTag = {
        target = optionTypes.imageTag;
        tests.typeChecking = {
          accepted.inputs = [
            "atag"
            "Atag"
            "0tag"
            "_tag"
            "ABCDEFGHIJKLMNOPQRSTUVWYXZabcdefghijklmnopqrstuvwxyz0123456789._-"
            "1"
            "a"
            "128charsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"
            "foo--bar-"
            "15.1.0"
            "v15.1.0"
            "24.04"
            "3.0.0-rc.3"
            "alpine-v17.9.0"
            "latest"
            "2p5yc7h20yc2ca8l1k3ajkn3w3d110xs"
          ];
          rejected.inputs = [
            ""
            " "
            ".tag_starting-with-dot"
            "-tag_starting-with-minus"
            "tag/with-slash"
            "tag with spaces"
            "tag&+with?disallowed#chars"
            "129charssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"
            "sha256:10901ccd8d249047f9761845b4594f121edef079cfd8224edebd9ea726f0a7f6" # digest
          ];
          inherit nonStringValuesRejected;
        };
      };
      imageName = {
        target = optionTypes.imageName;
        tests.typeChecking = {
          accepted.inputs = [
            "imagename"
            "nested/image/name"
            "a"
            "1"
            "abcdefghijklmnopqrstuvwxyz0123456789.a_a__a---a/abcdefghijklmnopqrstuvwxyz0123456789.a_a__a---a"
            "1.0.0"
            "nginx"
            "docker.io/library/debian"
            "registry.gitlab.com/yaook/k8s/ci"
          ];
          rejected.inputs = [
            ""
            " "
            "imagename_with space"
            "imagename_with-CAPITALS"
            ".imagename_starting-with-dot"
            "_imagename_starting-with-underscore"
            "-imagename_starting-with-minus"
            "An_imagename_starting-with-capital"
            "/imagename_starting-with-slash"
            "imagename_ending-with-slash/"
            "image___name_with-tripple-underscore"
            "imagename_w:th?disallowed+ch#rs"
          ];
          inherit nonStringValuesRejected;
        };
      };
      imageRef = {
        target = optionTypes.imageRef;
        tests.typeChecking = {
          # every concatenation with ':' of imageName and imageTag is a valid imageRef
          accepted.inputs = mapCartesianProduct ({
            imageName,
            imageTag,
          }: "${imageName}:${imageTag}") {
            imageName = imageName.tests.typeChecking.accepted.inputs;
            imageTag = imageTag.tests.typeChecking.accepted.inputs;
          };
          rejected.inputs =
            [""]
            # Any imageName/imageTag (without ':') on their own is not a valid imageRef
            ++ imageName.tests.typeChecking.accepted.inputs
            ++ filter (x: matchesRegex "^[^:]*$" x) imageName.tests.typeChecking.rejected.inputs
            ++ imageTag.tests.typeChecking.accepted.inputs
            ++ filter (x: matchesRegex "^[^:]*$" x) imageTag.tests.typeChecking.rejected.inputs
            # every concatenation with ':' of a valid imageName and an invalid imageTag is an invalid imageRef
            ++ mapCartesianProduct ({
              imageName,
              invalidImageTag,
            }: "${imageName}:${invalidImageTag}") {
              imageName = imageName.tests.typeChecking.accepted.inputs;
              invalidImageTag = imageTag.tests.typeChecking.rejected.inputs;
            }
            # every concatenation with ':' of an invalid imageName and a valid imageTag is an invalid imageRef
            ++ mapCartesianProduct ({
              invalidImageName,
              imageTag,
            }: "${invalidImageName}:${imageTag}") {
              invalidImageName = imageName.tests.typeChecking.rejected.inputs;
              imageTag = imageTag.tests.typeChecking.accepted.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
