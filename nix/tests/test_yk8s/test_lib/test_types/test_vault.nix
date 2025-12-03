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

  reservedNamespaceRoots = [
    "root"
    "sys"
    "audit"
    "auth"
    "cubbyhole"
    "identity"
  ];

  optionTypeUnitTests = {
    meta = {
      name = "vaultOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      namespaceName = {
        target = optionTypes.namespaceName;
        tests.typeChecking = {
          accepted.inputs =
            [
              "a"
              "foobar"
              "foo-bar"
              "foo:bar"
              "foo\"bar"
              "nested/foobar"
              "even/more/nested/foobar"
              "yaook/k8s"
            ]
            # the first segment of a namespaceName is allowed to start with a reserved string
            ++ builtins.map (x: "${x}-foo") reservedNamespaceRoots
            # any nesting of a valid childNamespaceNameSegment is a valid namespaceName
            ++ builtins.map (x: "foo/${x}") childNamespaceNameSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "end/with/slash/"
              "contain spaces "
              "+"
              "{{ identity.entity.id }}"
              "foo/{{ identity.entity.id }}"
              "{{ identity.entity.id }}/bar"
              "{{}}"
            ]
            # reserved strings are allowed to be used as the first segment of a namespace name
            ++ reservedNamespaceRoots
            ++ builtins.map (x: "${x}/foo") reservedNamespaceRoots;
          inherit nonStringValuesRejected;
        };
      };
      childNamespaceNameSegment = {
        target = optionTypes.childNamespaceNameSegment;
        tests.typeChecking = {
          accepted.inputs =
            [
              "a"
              "foobar"
              "foo-bar"
              "foo:bar"
              "foo\"bar"
            ]
            # reserved strings are allowed to be used as segment of a *child* namespace name
            ++ reservedNamespaceRoots;
          rejected.inputs = [
            ""
            "foobar/"
            "nested/foobar"
            "contain spaces "
            "+"
            "{{ identity.entity.id }}"
            "foo/{{ identity.entity.id }}"
            "{{ identity.entity.id }}/bar"
            "{{}}"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
