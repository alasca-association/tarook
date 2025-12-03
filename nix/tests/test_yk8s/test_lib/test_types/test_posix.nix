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
      name = "posixOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      pathSegment = {
        target = optionTypes.pathSegment;
        tests.typeChecking = {
          accepted.inputs = [
            "foobar"
            "path segment with spaces"
            "default.nix"
            "foo:bar%()_34-12"
          ];
          rejected.inputs = [
            ""
            "."
            ".."
            "relative/path"
            "relative/path/"
            "/absolute/path"
            "/absolute/path/"
            "./foobar"
            "relative/../path"
            "/./absolute/path/"
            "/absolute/../path"
          ];
          inherit nonStringValuesRejected;
        };
      };
      pathSegmentWithSpecial = {
        target = optionTypes.pathSegmentWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            [
              "."
              ".."
            ]
            # pathSegmentWithSpecial is a superset of pathSegment
            ++ pathSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs = [
            ""
            "relative/path"
            "relative/path/"
            "/absolute/path"
            "/absolute/path/"
            "./foobar"
            "relative/../path"
            "/./absolute/path/"
            "/absolute/../path"
          ];
          inherit nonStringValuesRejected;
        };
      };
      filename = {
        target = optionTypes.filename;
        # filename is an alias type for pathSegment
        tests.typeChecking = pathSegment.tests.typeChecking;
      };
      relativePath = {
        target = optionTypes.relativePath;
        tests.typeChecking = {
          accepted.inputs =
            [
              "relative/path"
              "relative/path/"
              "relative/posix path/ with spaces"
              "relative///path//"
            ]
            # pathSegmentWithSpecial is a superset of pathSegment
            ++ pathSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "."
              ".."
              "./foobar"
              "relative/../path"
            ]
            # relativePath is mutal exlusive with absolutePath(WithSpecial)
            ++ absolutePathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      relativePathWithSpecial = {
        target = optionTypes.relativePathWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            [
              "./foobar"
              "relative/../path"
            ]
            # pathSegmentWithSpecial is a superset of relativePath
            ++ pathSegmentWithSpecial.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # relativePathWithSpecial is mutal exlusive with absolutePath(WithSpecial)
            ++ absolutePathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      absolutePath = {
        target = optionTypes.absolutePath;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every relativePath prefixed with '/' becomes an absolutePath
            ++ map (relPath: "/${relPath}")
            relativePath.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "/./absolute/path/"
              "/absolute/../path"
            ]
            # absolutePath is mutal exlusive with relativePath(WithSpecial)
            ++ relativePathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      absolutePathWithSpecial = {
        target = optionTypes.absolutePathWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every relativePathWithSpecial prefixed with '/' becomes an absolutePathWithSpecial
            ++ map (relPath: "/${relPath}")
            relativePathWithSpecial.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # absolutePathWithSpecial is mutal exclusive with relativePathWithSpecial
            ++ relativePathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      path = {
        target = optionTypes.path;
        tests.typeChecking = {
          # path is a superset of relativePath and absolutePath
          relativeAccepted = relativePath.tests.typeChecking.accepted;
          absoluteAccepted = absolutePath.tests.typeChecking.accepted;
          rejected.inputs = [
            ""
            "."
            ".."
            "./foobar"
            "relative/../path"
            "/./absolute/path/"
            "/absolute/../path"
          ];
          inherit nonStringValuesRejected;
        };
      };
      pathWithSpecial = {
        target = optionTypes.pathWithSpecial;
        tests.typeChecking = {
          # pathWithSpecial is a superset of relativePathWithSpecial and absolutePathWithSpecial
          relativeAccepted = relativePathWithSpecial.tests.typeChecking.accepted;
          absoluteAccepted = absolutePathWithSpecial.tests.typeChecking.accepted;
          rejected.inputs = [""];
          inherit nonStringValuesRejected;
        };
      };

      userName = {
        target = optionTypes.userName;
        tests.typeChecking = {
          accepted.inputs = [
            "yaook"
            "yaook-k8s"
            "55five"
            "foo.BAR.baz-1_2"
          ];
          rejected.inputs = [
            ""
            "foo bar"
            "sla/sh"
            "foo:bar-2"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
