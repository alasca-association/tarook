{
  lib,
  ctx,
  ...
}:
with lib; let
  inherit (lib) runTests;
  yk8s-lib.transform = import (ctx.importPath + "/../transform.nix") {inherit lib;};
  yk8s-lib.types = import (ctx.importPath) {inherit lib;};

  # --- Transforming functions --- #

  /*
  Convert an option type test suite structured like below
  into the format nixpkgs.lib.runTests expects.

  Supports type checking and description tests.

  {
    meta = {                             # metadata of the test suite
      name = <str>;                      # name of the test suite
      targets = <attrset>;               # all targets of the test suite
      predicates = {
        "pass": <str>;                   # case insensitive keyword for tests expected to pass
        "fail": <str>;                   # case insensitive keyword for tests expected to fail
      };
    }
    units = {
      <testUnitName> = {
        target = <optionType>;           # <-- the optionType to unit-test
        tests = {
          <testClass:typeChecking> = {   # <-- the kind of test to perform
            <testNameWithKeyword1> = {   # <-- name of the test (must contain one of the predicates)
              params = [ <arg> <arg> ];  # <-- optional: option type arguments (positional)
              inputs = [<input1> ...];   # <-- list of input values to type check
            };
            ...
            <testNameWithKeywordN> = {
              ...
            };
          };
          <testClass:description> = {    # <-- the kind of test to perform
            <testName1> = {              # <-- name of the test
              params = [ <arg> <arg> ];  # <-- optional: option type arguments (positional)
              text = <str>;              # <-- expected description text
            };
            ...
            <testNameN> = {
              ...
            };
          };
        };
      };
    };
  }
  */
  mkRunTests = testSuite: let
    inherit (builtins) hasAttr isAttrs length;
    inherit (lib) assertMsg;
    inherit (lib.attrsets) foldlAttrs mapAttrsToList;
    inherit (yk8s-lib.transform) addPrefix;

    /*
    Create a kind of test
    */
    mkTest = kind: name: target: data: let
      inherit (builtins) isAttrs isString;
    in
      assert assertMsg (isString name)
      "mkTest: test name must be a string";
      assert assertMsg (isAttrs data)
      "mkTest: test data must be an attrset";
        if kind == "typeChecking"
        then (mkTypeCheckingTest name target data)
        else if kind == "description"
        then (mkTypeDescriptionTest name target data)
        else throw "Unsupported test class";

    /*
    Create a test that checks a type's description
    */
    mkTypeDescriptionTest = name: target: data: let
      inherit (builtins) foldl' hasAttr isString;
      inherit (lib.types) isOptionType;

      # resolve parameterized targets
      _target =
        if hasAttr "params" data
        then foldl' (acc: param: acc param) target data.params
        else target;
    in
      assert assertMsg (isOptionType _target)
      "mkTypeDescriptionTest: target must be an OptionType or function that returns one";
      assert assertMsg (
        hasAttr "text" data && isString data.text
      ) "Expected type description text must be a string and be specified"; {
        expr = _target.description;
        expected = data.text;
      };

    /*
    Create a test that checks a type's `check` method
    */
    mkTypeCheckingTest = name: target: data: let
      inherit (builtins) foldl' hasAttr length map;
      inherit (lib.strings) hasInfix toLower;
      inherit (lib.types) isOptionType;

      pass = testSuite.meta.predicates.pass;
      fail = testSuite.meta.predicates.fail;

      # resolve parameterized targets
      _target =
        if hasAttr "params" data
        then foldl' (acc: param: acc param) target data.params
        else target;
    in
      assert assertMsg (isOptionType _target)
      "mkTypeCheckingTest: target must be an OptionType or a function returning one";
      assert assertMsg (
        hasAttr "inputs" data && length data.inputs > 0
      ) "Type checking test must specify at least one input"; {
        expr = map (x: _target.check x) data.inputs;
        expected =
          map (
            x:
              if hasInfix pass (toLower name)
              then true
              else if hasInfix fail (toLower name)
              then false
              else throw "Invalid test name (must contain '${pass}' or '${fail}' predicate)"
          )
          data.inputs;
      };
  in
    assert assertMsg (isAttrs testSuite)
    "Test suite must be an attrset";
    assert assertMsg (hasAttr "meta" testSuite)
    "Test suite must have the 'meta' attribute";
    assert assertMsg (hasAttr "name" testSuite.meta)
    "Test suite must specify 'meta.name'";
    assert assertMsg (hasAttr "targets" testSuite.meta)
    "Test suite must specify 'meta.targets'";
    assert assertMsg (hasAttr "predicates" testSuite.meta)
    "Test suite must specify 'meta.predicates'";
    assert assertMsg (
      let o = testSuite.meta.predicates; in (hasAttr "pass" o) && (hasAttr "fail" o)
    ) "Test suite must define 'meta.predicates.pass' and 'meta.predicates.fail'";
    assert assertMsg (hasAttr "units" testSuite)
    "Test suite has no 'units' attribute";
    # TODO: Check that both lists actually contain the same items and output the difference if any
    #       (This is a bit complicated and might not be worth it)
    assert assertMsg (
      length (mapAttrsToList (_: unit: unit.target) testSuite.units)
      == length (mapAttrsToList (_: target: target) testSuite.meta.targets)
    ) "Test suite must test all targets";
      addPrefix "test_" ( # NOTE: runTests only executes attributes starting with 'test'
        foldlAttrs (
          accUnitTests: testUnitName: testUnit:
            accUnitTests
            // foldlAttrs (
              accTestClasses: testClassName: testClass:
                accTestClasses
                // foldlAttrs (
                  accTests: testName: test:
                    accTests
                    // {
                      "${testUnitName}_${testClassName}_${testName}" =
                        mkTest testClassName testName testUnit.target test;
                    }
                ) {}
                testClass
            ) {}
            testUnit.tests
        ) {}
        testSuite.units
      );

  # --- Test suites --- #

  optionTypeUnitTests = let
    inherit (builtins) elemAt filter isList map match toString;
    inherit (lib.lists) intersectLists range;
    inherit (lib) mapCartesianProduct;
    inherit (yk8s-lib.transform) matchesRegex;

    # --- functions --- #

    /*
    Return a list of items from a list of strings that do not exceed a certain length

    Arguments:
    - maxLength: Maximum length of a string
    - *: List of strings

    Example:
      filterStringsByMaxLength 4 ["foo" "four" "five5"] -> ["foo" "four"]
    */
    selectStringsByMaxLength = maxLength:
      filter (x: (builtins.stringLength x) <= maxLength);

    # --- resuables --- #

    nonStringValuesRejected.inputs = reusableValues.nonString;
    nonAttrsValuesRejected.inputs = reusableValues.nonAttrs;
    reusableValues = let
      null_ = [null];
      booleans = [true false];
      strings = ["" "a"];
      integers = [0 1 25 (-19)];
      lists = [["a"]];
      attrsets = [{a = "b";}];
      paths = [/nix/store];
      functions = [(x: x)];
    in rec {
      nonStringInteger = null_ ++ booleans ++ lists ++ attrsets ++ paths ++ functions;
      nonString = null_ ++ booleans ++ integers ++ lists ++ attrsets ++ paths ++ functions;
      nonInteger = null_ ++ booleans ++ strings ++ lists ++ attrsets ++ paths ++ functions;
      nonAttrs = null_ ++ booleans ++ strings ++ integers ++ lists ++ paths ++ functions;
      anyType = null_ ++ booleans ++ strings ++ integers ++ lists ++ attrsets ++ paths ++ functions;

      rfc1123SubdomainNames =
        [
          "cloud.yaook.k8s"
          "foo-bar.baz"
          # IETF RFC1123, section 2.1: MUST handle host names of up to 63 characters
          "name-with-253-characters-and-63-chars-for-each-label-aaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          # IETF RFC1123, section 2.1: SHOULD handle host names of up to 255 characters
          "name-with-255-chars-for-each-label-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          # IETF RFC1123, section 2.5 does not mention any length restrictions
          "name-with-256-chars-for-each-label-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ]
        ++ rfc1123SubdomainLabels;
      rfc1123SubdomainLabels =
        [
          "1"
          "1-name-starting-with-a-digit"
        ]
        ++ rfc1035SubdomainLabels;
      rfc1035SubdomainLabels = [
        "a"
        "name"
        "a-name-with-dashes"
        "foo--bar"
        "name-ending-with-a-digit1"
        # IETF RFC1123, section 2.1: MUST handle host names of up to 63 characters
        "label-with-63-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        # IETF RFC1123, section 2.1: SHOULD handle host names of up to 255 characters
        "label-with-255-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        # IETF RFC1123, section 2.5 does not mention any length restrictions
        "label-with-256-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      ];

      reservedVaultNamespaceRoots = [
        "root"
        "sys"
        "audit"
        "auth"
        "cubbyhole"
        "identity"
      ];

      rfc9293PortNumbers = {
        valid = [0 1 443 8080 35000 65535];
        invalid = [(-1) (-3462) 65536 80000];
      };
    };

    optionTypes = yk8s-lib.types;
  in {
    meta = {
      name = "optionTypeUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
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

      openstackAvailabilityZoneName = {
        target = optionTypes.openstackAvailabilityZoneName;
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
      openstackSwiftContainerName = {
        target = optionTypes.openstackSwiftContainerName;
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
      openstackFlavorName = {
        target = optionTypes.openstackFlavorName;
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
      openstackImageName = {
        target = optionTypes.openstackImageName;
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
      openstackKeypairName = {
        target = optionTypes.openstackKeypairName;
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
      openstackNetworkName = {
        target = optionTypes.openstackNetworkName;
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
      openstackServerGroupName = {
        target = optionTypes.openstackServerGroupName;
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
      openstackVolumeTypeName = {
        target = optionTypes.openstackVolumeTypeName;
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

      gitlabProjectId = {
        target = optionTypes.gitlabProjectId;
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
      gitlabTerraformStateName = {
        target = optionTypes.gitlabTerraformStateName;
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

      vaultNamespaceName = {
        target = optionTypes.vaultNamespaceName;
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
            # the first segment of a vaultNamespaceName is allowed to start with a reserved string
            ++ builtins.map (x: "${x}-foo") reusableValues.reservedVaultNamespaceRoots
            # any nesting of a valid vaultChildNamespaceNameSegment is a valid vaultNamespaceName
            ++ builtins.map (x: "foo/${x}") vaultChildNamespaceNameSegment.tests.typeChecking.accepted.inputs;
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
            ++ reusableValues.reservedVaultNamespaceRoots
            ++ builtins.map (x: "${x}/foo") reusableValues.reservedVaultNamespaceRoots;
          inherit nonStringValuesRejected;
        };
      };
      vaultChildNamespaceNameSegment = {
        target = optionTypes.vaultChildNamespaceNameSegment;
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
            ++ reusableValues.reservedVaultNamespaceRoots;
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

      posixPathSegment = {
        target = optionTypes.posixPathSegment;
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
      posixPathSegmentWithSpecial = {
        target = optionTypes.posixPathSegmentWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            [
              "."
              ".."
            ]
            # posixPathSegmentWithSpecial is a superset of posixPathSegment
            ++ posixPathSegment.tests.typeChecking.accepted.inputs;
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
      posixFilename = {
        target = optionTypes.posixFilename;
        # posixFilename is an alias type for posixPathSegment
        tests.typeChecking = posixPathSegment.tests.typeChecking;
      };
      relativePosixPath = {
        target = optionTypes.relativePosixPath;
        tests.typeChecking = {
          accepted.inputs =
            [
              "relative/path"
              "relative/path/"
              "relative/posix path/ with spaces"
              "relative///path//"
            ]
            # posixPathSegmentWithSpecial is a superset of posixPathSegment
            ++ posixPathSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "."
              ".."
              "./foobar"
              "relative/../path"
            ]
            # relativePosixPath is mutal exlusive with absolutePosixPath(WithSpecial)
            ++ absolutePosixPathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      relativePosixPathWithSpecial = {
        target = optionTypes.relativePosixPathWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            [
              "./foobar"
              "relative/../path"
            ]
            # posixPathSegmentWithSpecial is a superset of relativePosixPath
            ++ posixPathSegmentWithSpecial.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # relativePosixPathWithSpecial is mutal exlusive with absolutePosixPath(WithSpecial)
            ++ absolutePosixPathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      absolutePosixPath = {
        target = optionTypes.absolutePosixPath;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every relativePosixPath prefixed with '/' becomes an absolutePosixPath
            ++ map (relPath: "/${relPath}")
            relativePosixPath.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "/./absolute/path/"
              "/absolute/../path"
            ]
            # absolutePosixPath is mutal exlusive with relativePosixPath(WithSpecial)
            ++ relativePosixPathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      absolutePosixPathWithSpecial = {
        target = optionTypes.absolutePosixPathWithSpecial;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every relativePosixPathWithSpecial prefixed with '/' becomes an absolutePosixPathWithSpecial
            ++ map (relPath: "/${relPath}")
            relativePosixPathWithSpecial.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # absolutePosixPathWithSpecial is mutal exclusive with relativePosixPathWithSpecial
            ++ relativePosixPathWithSpecial.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      posixPath = {
        target = optionTypes.posixPath;
        tests.typeChecking = {
          # posixPath is a superset of relativePosixPath and absolutePosixPath
          relativeAccepted = relativePosixPath.tests.typeChecking.accepted;
          absoluteAccepted = absolutePosixPath.tests.typeChecking.accepted;
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
      posixPathWithSpecial = {
        target = optionTypes.posixPathWithSpecial;
        tests.typeChecking = {
          # posixPathWithSpecial is a superset of relativePosixPathWithSpecial and absolutePosixPathWithSpecial
          relativeAccepted = relativePosixPathWithSpecial.tests.typeChecking.accepted;
          absoluteAccepted = absolutePosixPathWithSpecial.tests.typeChecking.accepted;
          rejected.inputs = [""];
          inherit nonStringValuesRejected;
        };
      };

      posixUserName = {
        target = optionTypes.posixUserName;
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

      bytesPower2 = {
        target = optionTypes.bytesPower2;
        tests.typeChecking = {
          accepted.inputs = [
            "512KiB"
            "445MiB"
            "50GiB"
            "2TiB"
            "5.6GiB"
            "0.25TiB"
            "4.674GiB"
            "4.6745GiB"
          ];
          rejected.inputs =
            [
              ""
              "512kiB"
              "512KB"
              "50GB"
              ".34MiB"
              "5.6G"
              "500M"
              "50"
              "4.67"
              "4.674"
              "4.6745"
              50
              4.67
            ]
            # bytesPower2 is mutually exclusive with bytesPower10
            ++ bytesPower10.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      bytesPower10 = {
        target = optionTypes.bytesPower10;
        tests.typeChecking = {
          accepted.inputs = [
            "512kB"
            "445MB"
            "50GB"
            "2TB"
            "5.6GB"
            "0.25TB"
            "4.674GB"
            "4.6745GB"
          ];
          rejected.inputs =
            [
              ""
              "512KiB"
              "50GiB"
              ".34MB"
              "50"
              "4.67"
              "4.674"
              "4.6745"
              50
              4.67
            ]
            # bytesPower10 is mutually exclusive with bytesPower2
            ++ bytesPower2.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };

      ipv4Addr = {
        target = optionTypes.ipv4Addr;
        tests.typeChecking = {
          accepted.inputs = [
            "192.0.2.0"
            "192.0.2.1"
            "192.0.2.135"
            "198.51.100.0"
            "198.51.100.10"
            "198.51.100.255"
            "203.0.113.0"
            "127.0.0.1"
            "1.1.1.1"
            "100.127.255.255"
            "239.2.5.150"
          ];
          rejected.inputs =
            [
              ""
              "2886794753"
              "0xAC10FE01"
              "127.1"
              "127.65530"
              "192.0.2.0.45"
              ".1.1.1"
              "1.1.1."
            ]
            # ipv4Addr is mutually exclusive with ipv4Cidr, ipv6Addr and ipv6Cidr
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv4Cidr = {
        target = optionTypes.ipv4Cidr;
        tests.typeChecking = {
          # every valid ipv4Addr cidr-suffixed with 0 to 32 is a valid ipv4Cidr
          accepted.inputs = mapCartesianProduct ({
            ipv4Addr,
            ipv4CidrSuffix,
          }: "${ipv4Addr}/${ipv4CidrSuffix}") {
            ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
            ipv4CidrSuffix = map (x: toString x) (range 0 32);
          };
          rejected.inputs =
            [
              ""
              "192.0.2.0"
              "192.0.2.1/33"
              "192.0.2.1/033"
              "192.0.2.135/100"
              "192.0.2.135/"
              "198.51.100.0/-2"
              "2886794753/24"
              "0xAC10FE01/32"
              "127.1/24"
              "127.65530/24"
              ".1.1.1/24"
              "1.1.1./24"
            ]
            # ipv4Cidr is mutually exclusive with ipv4Addr, ipv6Addr and ipv6Cidr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv4AddrWithPort = {
        target = optionTypes.ipv4AddrWithPort;
        tests.typeChecking = {
          accepted.inputs = mapCartesianProduct ({
            ipv4Addr,
            tcpPort,
          }: "${ipv4Addr}:${toString tcpPort}") {
            ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
            tcpPort = reusableValues.rfc9293PortNumbers.valid;
          };
          rejected.inputs =
            [
              ""
              "foobar"
              "foo:bar"
              "example.com:443"
              "127.0.0.1:foo"
              ":443"
              "127.0.0.1:"
            ]
            # every combination of ipv4Addr and port number where at least one is invalid
            ++ mapCartesianProduct ({
              invalidIpv4Addr,
              tcpPort,
            }: "${invalidIpv4Addr}:${toString tcpPort}") {
              invalidIpv4Addr = filter (x: matchesRegex "^.+:.+$" x) ipv4Addr.tests.typeChecking.rejected.inputs;
              tcpPort = reusableValues.rfc9293PortNumbers.valid;
            }
            ++ mapCartesianProduct ({
              ipv4Addr,
              invalidTcpPort,
            }: "${ipv4Addr}:${toString invalidTcpPort}") {
              ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            }
            ++ mapCartesianProduct ({
              invalidIpv4Addr,
              invalidTcpPort,
            }: "${invalidIpv4Addr}:${toString invalidTcpPort}") {
              invalidIpv4Addr = filter (x: matchesRegex "^.+:.+$" x) ipv4Addr.tests.typeChecking.rejected.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };
      ipv6Addr = {
        target = optionTypes.ipv6Addr;
        tests.typeChecking = {
          accepted.inputs = [
            "::"
            "::1"
            "2001:db8::"
            "2001:db8:50b:3034::"
            "fe80::876:7cff:fe9e:2f27"
            "FE80::876:7CFF:fE9E:2F27"
            "3fff::"
            "3FFF::"
          ];
          rejected.inputs =
            [
              ""
              ":"
              "ba732:db:5023bc123:3034:fba:24:34fb:ba74:32d3"
              "hgow23:23saa:13::"
              "349102305239191823"
              "abc-42:23/af"
            ]
            # ipv6Addr is mutually exclusive with ipv4Addr, ipv4Cidr and ipv6Cidr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv6Cidr = {
        target = optionTypes.ipv6Cidr;
        tests.typeChecking = {
          # every valid ipv6Addr cidr-suffixed with 0 to 64 is a valid ipv6Cidr
          accepted.inputs = mapCartesianProduct ({
            ipv6Addr,
            ipv6CidrSuffix,
          }: "${ipv6Addr}/${ipv6CidrSuffix}") {
            ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
            ipv6CidrSuffix = map (x: toString x) (range 0 64);
          };
          rejected.inputs =
            [
              ""
              "::/181"
              "3fff::/010"
              "3fff::/"
              "349102305239191823/64"
            ]
            # ipv6Cidr is mutually exclusive with ipv4Addr, ipv4Cidr and ipv6Addr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv6AddrWithPort = {
        target = optionTypes.ipv6AddrWithPort;
        tests.typeChecking = {
          accepted.inputs = mapCartesianProduct ({
            ipv6Addr,
            tcpPort,
          }: "[${ipv6Addr}]:${toString tcpPort}") {
            ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
            tcpPort = reusableValues.rfc9293PortNumbers.valid;
          };
          rejected.inputs =
            [
              ""
              "foobar"
              "foo:bar"
              "example.com:443"
              "[::1]:foo"
              ":443"
              "[::1]:"
            ]
            # every combination of ipv6Addr and port number where at least one is invalid
            ++ mapCartesianProduct ({
              invalidIpv6Addr,
              tcpPort,
            }: "[${invalidIpv6Addr}]:${toString tcpPort}") {
              invalidIpv6Addr = filter (x: matchesRegex "^.+:.+$" x) ipv6Addr.tests.typeChecking.rejected.inputs;
              tcpPort = reusableValues.rfc9293PortNumbers.valid;
            }
            ++ mapCartesianProduct ({
              ipv6Addr,
              invalidTcpPort,
            }: "[${ipv6Addr}]:${toString invalidTcpPort}") {
              ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            }
            ++ mapCartesianProduct ({
              invalidIpv6Addr,
              invalidTcpPort,
            }: "[${invalidIpv6Addr}]:${toString invalidTcpPort}") {
              invalidIpv6Addr = filter (x: matchesRegex "^.+:.+$" x) ipv6Addr.tests.typeChecking.rejected.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };

      privateUseAutonomousSystemNumber = {
        target = optionTypes.privateUseAutonomousSystemNumber;
        tests.typeChecking = {
          accepted.inputs = [
            4200000000
            4200001000
            4294452900
            4294967294
            64512
            64933
            65534
          ];
          rejected.inputs = [
            4199999999
            4294967295
            64511
            64511.5
            65535
            23849242
            0
            (-34)
            ""
            "foobar"
            "4200001000"
          ];
          nonIntegerValuesRejected.inputs = reusableValues.nonInteger;
        };
      };

      subdomainLabel = {
        target = optionTypes.subdomainLabel;
        tests.typeChecking = {
          accepted.inputs = [
            "foo"
            "4foo"
            "foo-bar-baz"
            "a"
            "ab"
            "loooooooooooooooooooooooooong-subomain-label-with-63-characters"
            "looooooooooooooooooooooooooong-subomain-label-with-64-characters"
          ];
          rejected.inputs = [
            ""
            "foo%bar-label"
            "with spaces "
            "foobar-"
            "-foobar"
            "foo.bar"
          ];
          inherit nonStringValuesRejected;
        };
      };
      subdomainName = {
        target = optionTypes.subdomainName;
        tests.typeChecking = {
          accepted.inputs =
            [
              "foo.bar"
              "foo.bar.baz"
              "FOO.baR.baz"
              "foo-bar.baz"
              "3www.example.com"
              "192.168.0.1"
              "subdomain-name-that-is-253-characters-long.lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-sed-do-eiusmod-tempor-incididunt-ut-labore-et-dolore-magna-aliqua-Ut-enim-ad-minim-veniam-quis-nostrud-exercitation-ullamco-laboris-nisi-ut-aliquip-xxxxxxx"
              "subdomain-name-that-is-254-characters-long.lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-sed-do-eiusmod-tempor-incididunt-ut-labore-et-dolore-magna-aliqua-Ut-enim-ad-minim-veniam-quis-nostrud-exercitation-ullamco-laboris-nisi-ut-aliquip-xxxxxxxx"
            ]
            # subdomainName is a superset of subdomainLabel
            ++ subdomainLabel.tests.typeChecking.accepted.inputs
            ++ map (label: "${label}.example.com") subdomainLabel.tests.typeChecking.accepted.inputs;
          rejected.inputs = [
            ""
            "foo%bar-label"
            "with spaces "
            "foobar-"
            "-foobar"
            "foo_bar.baz"
            ".example.com"
            "example.com."
            "-.example.com"
            "a-.example.com"
            "a-.example.com"
            "foo.-example.com"
          ];
          inherit nonStringValuesRejected;
        };
      };

      urlPathSegment = {
        target = optionTypes.urlPathSegment;
        tests.typeChecking = {
          accepted.inputs = [
            "urlpathsegment"
            "url%20path%20segment%20with%20%25-encoded%20spaces"
            "index.html"
            "."
          ];
          rejected.inputs = [
            ""
            "url path segment with spaces"
            "invalid%G3char%3kencoding"
            "path-segment-with#fragment"
            "relative/path"
            "/absolute/path"
          ];
          inherit nonStringValuesRejected;
        };
      };
      relativeUrlPath = {
        target = optionTypes.relativeUrlPath;
        tests.typeChecking = {
          accepted.inputs =
            [
              "relative/path"
              "relative/path/"
              "relative_path/foobar"
              "~/-weird_URL/$path=foo;bar+a(5*3,4)&/@:'"
              "."
            ]
            # relativeUrlPath is a superset of urlPathSegment
            ++ urlPathSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "/absolute/path"
              "path/with?query"
              "path/with#fragment"
              "path/with€unencoded`chars^"
            ]
            # relativeUrlPath is a superset of urlPathSegment
            ++ filter (x: matchesRegex "^[^/]*$" x) urlPathSegment.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpHostUrl = {
        target = optionTypes.httpHostUrl;
        tests.typeChecking = {
          accepted.inputs = [
            "http://example.com"
            "http://example.com:443"
            "http://example.com:" # allowed but URL normalizers should omit the ':'
            "http://user@example.com"
            "http://foo:aF0._~-!$&'()*+,;=%20@example.com"
            "http://uid=john.doe,ou=foo&bar,dc=example,dc=com@example.com"
          ];
          rejected.inputs = [
            ""
            "http://example.com/"
            "http://example.com/with/path"
            "http://user@here@example.com"
            "ftp://example.com"
            "https://" # valid URL but invalid for the http scheme
            "https://user@" # valid URL but invalid for the http scheme
          ];
          inherit nonStringValuesRejected;
        };
      };
      httpsHostUrl = {
        target = optionTypes.httpsHostUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpHostUrl starting with 'https' instead of 'http' becomes a httpsHostUrl
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpHostUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # every invalid httpHostUrl that does not start with 'https' is also an invalid httpsHostUrl
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpHostUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxHostUrl = {
        target = optionTypes.httpxHostUrl;
        # httpxHostUrl is a superset of httpHostUrl and httpsHostUrl
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpHostUrl.tests.typeChecking.accepted.inputs
            ++ httpsHostUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpHostUrl.tests.typeChecking.rejected.inputs
            httpsHostUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxHostPathUrl = {
        target = optionTypes.httpxHostPathUrl;
        # httpxHostPathUrl is a superset of httpHostPathUrl and httpsHostPathUrl
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpHostPathUrl.tests.typeChecking.accepted.inputs
            ++ httpsHostPathUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpHostPathUrl.tests.typeChecking.rejected.inputs
            httpsHostPathUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpHostPathUrl = {
        target = optionTypes.httpHostPathUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # httpHostPathUrl is a superset of httpHostUrl
            ++ httpHostUrl.tests.typeChecking.accepted.inputs
            # every httpHostUrl with a path appended becomes a httpHostPathUrl
            ++ map (url: "${url}/with/path")
            httpHostUrl.tests.typeChecking.accepted.inputs
            # every concatenation with '/' of httpHostUrl and relativeUrlPath becomes a httpHostPathUrl
            ++ mapCartesianProduct ({
              httpHostUrl,
              relativeUrlPath,
            }: "${httpHostUrl}/${relativeUrlPath}") {
              httpHostUrl = httpHostUrl.tests.typeChecking.accepted.inputs;
              relativeUrlPath = relativeUrlPath.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [""]
            # every concatenation with '/' of a valid httpHostUrl and an invalid relativeUrlPath (that does not start with '/') is an invalid httpHostPathUrl
            ++ mapCartesianProduct ({
              httpHostUrl,
              invalidRelativeUrlPath,
            }: "${httpHostUrl}/${invalidRelativeUrlPath}") {
              httpHostUrl = httpHostUrl.tests.typeChecking.accepted.inputs;
              invalidRelativeUrlPath =
                filter (x: matchesRegex "^[^/].*$" x) relativeUrlPath.tests.typeChecking.rejected.inputs;
            }
            # every concatenation with '/' of an invalid httpHostUrl and a valid relativeUrlPath is an invalid httpHostPathUrl
            ++ mapCartesianProduct ({
              invalidHttpHostUrl,
              relativeUrlPath,
            }: "${invalidHttpHostUrl}/${relativeUrlPath}") {
              invalidHttpHostUrl = [
                "http://user@here@example.com"
                "ftp://example.com"
                "https://" # valid URL but invalid for the http scheme
                "https://user@" # valid URL but invalid for the http scheme
              ];
              relativeUrlPath = relativeUrlPath.tests.typeChecking.accepted.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };
      httpsHostPathUrl = {
        target = optionTypes.httpsHostPathUrl;
        tests.typeChecking = {
          # every valid httpHostPathUrl starting with 'https' instead of 'http' becomes a httpsHostPathUrl
          accepted.inputs =
            []
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpHostPathUrl.tests.typeChecking.accepted.inputs;
          # every invalid httpHostPathUrl that does not start with 'https' is also an invalid httpsHostPathUrl
          rejected.inputs =
            [""]
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpHostPathUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxUrl = {
        target = optionTypes.httpxUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpUrl.tests.typeChecking.accepted.inputs
            ++ httpsUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpUrl.tests.typeChecking.rejected.inputs
            httpsUrl.tests.typeChecking.rejected.inputs;
        };
      };
      httpUrl = {
        target = optionTypes.httpUrl;
        tests.typeChecking = let
          urlQueryFragments.valid = [
            "?query"
            "#fragment"
            "?query#fragment"
            "#fragment?actually-not-a-query"
            "#fragment/With-all_unencoded~ch?rs.Foo"
            "?/query?With-#all_unencoded~chars.Foo"
            "#query%20with%20%25-encoded%20spaces"
          ];
        in {
          accepted.inputs =
            []
            # httpUrl is a superset of httpHost(Path)Url
            ++ httpHostPathUrl.tests.typeChecking.accepted.inputs
            # every httpHostPathUrl with a fragment and or query appended is a valid httpUrl
            ++ mapCartesianProduct ({
              hostPathUrl,
              urlQueryFragment,
            }: "${hostPathUrl}${urlQueryFragment}") {
              hostPathUrl = httpHostPathUrl.tests.typeChecking.accepted.inputs;
              urlQueryFragment = urlQueryFragments.valid;
            };
          rejected.inputs =
            [""]
            # every concatenation of a valid httpHostPathUrl and an invalid fragment or query is an invalid httpUrl
            ++ mapCartesianProduct ({
              httpHostPathUrl,
              invalidUrlQueryFragment,
            }: "${httpHostPathUrl}${invalidUrlQueryFragment}") {
              httpHostPathUrl = httpHostPathUrl.tests.typeChecking.accepted.inputs;
              invalidUrlQueryFragment = [
                "?query%8Xwith%JKinvalid%G3char%3kencoding"
                "#fragment%8Xwith%JKinvalid%G3char%3kencoding"
                "?valid-query#fragment%8Xwith%JKinvalid%G3char%3kencoding"
                "?query with€unencoded`chars^"
                "#fragment with€unencoded`chars^"
                "?valid-query#fragment with€unencoded`chars^"
              ];
            }
            # every concatenation of an invalid httpHostPathUrl and a valid fragment or query is an invalid httpUrl
            ++ mapCartesianProduct ({
              invalidHttpHostPathUrl,
              urlQueryFragment,
            }: "${invalidHttpHostPathUrl}${urlQueryFragment}") {
              invalidHttpHostPathUrl = [
                "http://user@here@example.com"
                "ftp://example.com"
                "https://" # valid URL but invalid for the http scheme
                "https://user@" # valid URL but invalid for the http scheme
              ];
              urlQueryFragment = urlQueryFragments.valid;
            };
          inherit nonStringValuesRejected;
        };
      };
      httpsUrl = {
        target = optionTypes.httpsUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpUrl starting with 'https' instead of 'http' becomes a httpsUrl
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # every invalid httpUrl that does not start with 'https' is also an invalid httpsUrl
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      xftpUrl = {
        target = optionTypes.xftpUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpUrl starting with 'ftp' or 'sftp' instead of 'http' becomes a xftpUrl
            ++ mapCartesianProduct ({
              xftpUrlScheme,
              urlWithoutScheme,
            }: "${xftpUrlScheme}${urlWithoutScheme}") {
              xftpUrlScheme = ["ftp" "sftp"];
              urlWithoutScheme =
                map (
                  url: let
                    m = match "^http(.*)$" url;
                  in
                    if isList m
                    then head m
                    else url
                )
                httpUrl.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [""]
            # every invalid httpUrl that does not start with 'ftp' or 'sftp' is also an invalid xftpUrl
            ++ mapCartesianProduct ({
              xftpUrlScheme,
              urlWithoutScheme,
            }: "${xftpUrlScheme}${urlWithoutScheme}") {
              xftpUrlScheme = ["ftp" "sftp"];
              urlWithoutScheme =
                map (
                  url: let
                    m = match "^http(.*)$" url;
                  in
                    if isList m
                    then head m
                    else url
                )
                httpUrl.tests.typeChecking.rejected.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };

      emailAddress = {
        target = optionTypes.emailAddress;
        tests.typeChecking = let
          localParts = {
            valid = [
              "user"
              "forname.surname"
              "!#$%&'*+-/=?^_`{|}~user.0815"
              "!!##\$\$%%&&''**++--//==??^^__``{{||}}~~uusseerr.00881155"
              "a.b"
            ];
            invalid = [
              ""
              " "
              "(comment)user"
              "user@domain"
              "user..sd"
              ".user"
              "user."
            ];
          };
          domainParts = {
            valid = [
              "domain"
              "domain.tld"
              "!#$%&'*+-/=?^_`{|}~domain.0815"
              "!!##\$\$%%&&''**++--//==??^^__``{{||}}~~doommaaiinn.00881155"
              "a.b"
            ];
            invalid = [
              ""
              " "
              "domain.tld(comment)"
              "user@domain"
              ".domain"
              "domain."
            ];
          };
        in {
          accepted.inputs = mapCartesianProduct ({
            localPart,
            domainPart,
          }: "${localPart}@${domainPart}") {
            localPart = localParts.valid;
            domainPart = domainParts.valid;
          };
          rejected.inputs =
            [""]
            # Any local/domain part (without '@') on their own is not a valid emailAddress
            ++ localParts.valid
            ++ filter (x: matchesRegex "^[^@]*$" x) localParts.invalid
            ++ domainParts.valid
            ++ filter (x: matchesRegex "^[^@]*$" x) domainParts.invalid
            # Any email address with an invalid local part is invalid
            ++ mapCartesianProduct ({
              invalidLocalPart,
              domainPart,
            }: "${invalidLocalPart}@${domainPart}") {
              invalidLocalPart = localParts.invalid;
              domainPart = domainParts.valid;
            }
            # Any email address with an invalid domain part is invalid
            ++ mapCartesianProduct ({
              localPart,
              invalidDomainPart,
            }: "${localPart}@${invalidDomainPart}") {
              localPart = localParts.valid;
              invalidDomainPart = domainParts.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };

      ipsecProposalStr = {
        target = optionTypes.ipsecProposalStr;
        tests.typeChecking = {
          accepted.inputs = [
            "aes256gcm16-aes128gcm16"
            "aes256gcm16-aes192gcm16-prfsha384-prfsha256-ecp384-modp3072"
            "aes256gcm16-prfsha384-ecp384-aes192gcm16-prfsha256-modp3072"
            "aes256gcm16"
            "AES256GCM16"
            "sha1_160"
          ];
          # The following ones should be invalid ipsec algorithm names but are currently accepted
          invalidAlgosAccepted.inputs = [
            "_sha1_160"
            "1234"
            "a"
          ];
          rejected.inputs = [
            ""
            " "
            "aes256gcm16.invalid?foo"
            "--"
            "aes256gcm16--aes128gcm16"
          ];
          inherit nonStringValuesRejected;
        };
      };

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

      ociImageTag = {
        target = optionTypes.ociImageTag;
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
      ociImageName = {
        target = optionTypes.ociImageName;
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
      ociImageRef = {
        target = optionTypes.ociImageRef;
        tests.typeChecking = {
          # every concatenation with ':' of ociImageName and ociImageTag is a valid ociImageRef
          accepted.inputs = mapCartesianProduct ({
            ociImageName,
            ociImageTag,
          }: "${ociImageName}:${ociImageTag}") {
            ociImageName = ociImageName.tests.typeChecking.accepted.inputs;
            ociImageTag = ociImageTag.tests.typeChecking.accepted.inputs;
          };
          rejected.inputs =
            [""]
            # Any ociImageName/ociImageTag (without ':') on their own is not a valid ociImageRef
            ++ ociImageName.tests.typeChecking.accepted.inputs
            ++ filter (x: matchesRegex "^[^:]*$" x) ociImageName.tests.typeChecking.rejected.inputs
            ++ ociImageTag.tests.typeChecking.accepted.inputs
            ++ filter (x: matchesRegex "^[^:]*$" x) ociImageTag.tests.typeChecking.rejected.inputs
            # every concatenation with ':' of a valid ociImageName and an invalid ociImageTag is an invalid ociImageRef
            ++ mapCartesianProduct ({
              ociImageName,
              invalidOciImageTag,
            }: "${ociImageName}:${invalidOciImageTag}") {
              ociImageName = ociImageName.tests.typeChecking.accepted.inputs;
              invalidOciImageTag = ociImageTag.tests.typeChecking.rejected.inputs;
            }
            # every concatenation with ':' of an invalid ociImageName and a valid ociImageTag is an invalid ociImageRef
            ++ mapCartesianProduct ({
              invalidOciImageName,
              ociImageTag,
            }: "${invalidOciImageName}:${ociImageTag}") {
              invalidOciImageName = ociImageName.tests.typeChecking.rejected.inputs;
              ociImageTag = ociImageTag.tests.typeChecking.accepted.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };

      k8sClusterName = {
        target = optionTypes.k8sClusterName;
        tests.typeChecking = {
          accepted.inputs = [
            "managed-k8s"
            "devcluster"
            "1cluster1"
            "clusterNameWithCapitals"
            "cluster.name"
            "cluster-name-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            ""
            "cluster name with spaces"
          ];
        };
      };
      k8sVersion = {
        target = optionTypes.k8sVersion;
        tests.description = {
          twoKubernetesVersions = {
            params = [[[1 29] [1 30]]];
            text = "Kubernetes version (one of: 1.29.x, 1.30.x)";
          };
        };
        tests.typeChecking = {
          accepted = {
            params = [[[1 29] [1 30]]];
            inputs = [
              "1.29.0"
              "1.29.3"
              "1.29.12"
              "1.30.0"
              "1.30.4"
              "1.30.14"
            ];
          };
          rejected = {
            params = [[[1 29] [1 30]]];
            inputs = [
              ""
              "1"
              "1.29"
              "1.30"
              "1.31"
              "1.31.0"
              "1.31.3"
              "1.31.12"
              ".31.12"
              "-3.42"
              "1.29.3-alpha"
              "1.29.3+2ad73da"
            ];
          };
        };
      };
      k8sQuantity = {
        target = optionTypes.k8sQuantity;
        tests.typeChecking = {
          accepted.inputs = [
            "300"
            "3k"
            "50Ki"
            "2.6Gi"
            "2.66Gi"
            "2.666Gi"
            "4e30"
            "-1024"
            "-5Ti"
            "4."
            ".68"
            ".688"
            "4e-40"
          ];
          rejected.inputs = [
            ""
            "2.6666Gi" # more than three decimal places
            ".6888" # more than three decimal places
            "4.5.6m"
            "45GM"
            "1K"
            "4ki"
            "2.6 Gi"
          ];
          inherit nonStringValuesRejected;
        };
      };
      k8sThreshold = {
        target = optionTypes.k8sThreshold;
        tests.typeChecking = {
          accepted.inputs =
            # every percentage from 0 to 205 (and beyond) is a valid k8sThreshold
            map (x: "${toString x}%") (range 0 205)
            # every k8sQuantity is also a valid k8sThreshold
            ++ k8sQuantity.tests.typeChecking.accepted.inputs;
          rejected.inputs = [
            ""
            " "
            "-0%"
            "-1%"
            "050%"
            "%"
            "50%4"
          ];
          inherit nonStringValuesRejected;
        };
      };
      k8sServiceType = {
        target = optionTypes.k8sServiceType;
        tests.typeChecking = {
          accepted.inputs = [
            "ClusterIP"
            "NodePort"
            "LoadBalancer"
            "ExternalName"
          ];
          rejected.inputs = [
            ""
            " "
            "foobar"
            "NodeIP"
            "Node"
          ];
          inherit nonStringValuesRejected;
        };
      };
      k8sObjectName = {
        target = optionTypes.k8sObjectName;
        tests.typeChecking = rec {
          accepted.inputs = [
            "calico-apiserver-78b49d765f-pdlns"
            "kube-proxy-kklwb"
          ];
          # NOTE: k8s subdomain labels and names must not exceed 63 and 253 characters respectively
          rfc1123SubdomainNamesAccepted.inputs = selectStringsByMaxLength 253 reusableValues.rfc1123SubdomainNames;
          rfc1123SubdomainLabelsAccepted.inputs = selectStringsByMaxLength 63 reusableValues.rfc1123SubdomainLabels;
          rfc1035SubdomainLabelsAccepted.inputs = selectStringsByMaxLength 63 reusableValues.rfc1035SubdomainLabels;
          rejected.inputs = [
            ""
            "foo..bar"
            "-foobar"
            ".foobar"
            "names%with+special~chars"
            "names-with-CAPITALS"
            "Capitalname"
            "capitalName"
            "name/with-a-slash"
            "name-ending-with-a-dash-"
            "-name-starting-with-a-dash-"
            # NOTE: k8s subdomain labels and names must not exceed 63 and 253 characters respectively
            "label-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaa"
            "subdomain-name-with-254-charaters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          inherit nonStringValuesRejected;
        };
      };
      k8sNamespaceName = {
        target = optionTypes.k8sNamespaceName;
        tests.typeChecking = {
          accepted.inputs = ["kube-system"];

          # k8sNamespaceName is a subset of k8sObjectName (subdomain labels)
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];

          inherit nonStringValuesRejected;
        };
      };
      k8sStorageClassName = {
        target = optionTypes.k8sStorageClassName;
        tests.typeChecking = {
          accepted.inputs = ["csi-sc-cinderplugin"];

          # k8sStorageClassName is equal to k8sObjectName
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      k8sSecretName = {
        target = optionTypes.k8sSecretName;
        tests.typeChecking = {
          accepted.inputs = ["sh.helm.release.v1.calico.v1"];

          # k8sSecretName is equal to k8sObjectName
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      k8sServiceName = {
        target = optionTypes.k8sServiceName;
        tests.typeChecking = {
          accepted.inputs = ["kube-dns"];

          # k8sServiceName is a subset of k8sObjectName
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];
          rfc1123SubdomainLabelsRejected.inputs = ["1name"];

          inherit nonStringValuesRejected;
        };
      };
      k8sIngressClassName = {
        target = optionTypes.k8sIngressClassName;
        tests.typeChecking = {
          accepted.inputs = ["haproxy-prod"];

          # k8sIngressClassName is equal to k8sObjectName
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      k8sIssuerName = {
        target = optionTypes.k8sIssuerName;
        tests.typeChecking = {
          accepted.inputs = ["selfsigned-issuer"];

          # k8sIssuerName is equal to k8sObjectName
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      k8sPodContainerName = {
        target = optionTypes.k8sPodContainerName;
        tests.typeChecking = {
          accepted.inputs = ["kube-state-metrics"];

          # k8sNamespaceName is a subset of k8sObjectName (subdomain labels)
          inherit (k8sObjectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (k8sObjectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];

          inherit nonStringValuesRejected;
        };
      };
      k8sLabelPrefix = {
        target = optionTypes.k8sLabelPrefix;
        tests.typeChecking = {
          # every rfc1123SubdomainName that does not exceed 253 characters is a valid k8sLabelPrefix
          accepted.inputs =
            [
              "k8s-app"
              "app.kubernetes.io"
              "dotted-prefix-with-253-characters-aaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaa"
            ]
            ++ selectStringsByMaxLength 253 reusableValues.rfc1123SubdomainNames;
          rejected.inputs = [
            ""
            " "
            "prefix-with-trailing-slash/"
            "prefix-with-two-trailing-slashes//"
            "prefix-with-a/slash"
            "prefix&with+disallowed#chars"
            "prefix with spaces"
            "dotted-prefix-with-254-characters-aaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaa"
          ];

          inherit nonStringValuesRejected;
        };
      };
      k8sLabelValue = {
        target = optionTypes.k8sLabelValue;
        tests.typeChecking = {
          accepted.inputs = [
            ""
            "090f35a2-4dfd-426e-8ece-48bf15d08a8f"
            "openstack-cinder-csi-2.30.0"
            "calico-apiserver"
            "value"
            "ValueA"
            "1value1"
            "a"
            "1"
            "foo-BAR_baz.01"
            "foo---bar..__baz"
            "value-with-63-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            " "
            "_value_starting-with-an-underscore"
            "-value_starting-with-a-dash"
            ".value_starting-with-a-dot"
            "value_ending-with-an-underscore_"
            "value_ending-with-a-dash-"
            "value_ending-with-a-dot."
            "value_with/slash"
            "value_with space"
            "value_with+disa!!owed%ch&rs"
            "value-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            "value=foo"
          ];

          inherit nonStringValuesRejected;
        };
      };
      k8sLabel = {
        target = optionTypes.k8sLabel;
        tests.typeChecking = let
          k8sLabelNames = {
            valid = [
              "name"
              "NameA"
              "1name1"
              "a"
              "1"
              "foo-BAR_baz.01"
              "foo---bar..__baz"
              "name-with-63-characters-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            ];
            invalid = [
              ""
              " "
              "_name_starting-with-an-underscore"
              "-name_starting-with-a-dash"
              ".name_starting-with-a-dot"
              "name_ending-with-an-underscore_"
              "name_ending-with-a-dash-"
              "name_ending-with-a-dot."
              "name-ending-with-slash/"
              "/name-starting-with-slash"
              "name-with/slash"
              "name-with/two/slashes"
              "name-with space"
              "name_with+disa!!owed%ch&rs"
              "name-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
              "name=value"
            ];
          };
        in {
          accepted.inputs =
            ["k8s-app" "app.kubernetes.io/name"]
            # every k8sLabelName on its own is a k8sLabel
            ++ k8sLabelNames.valid
            # every concatenation with '/' of k8sLabelPrefix and k8sLabelName is a k8sLabel
            ++ mapCartesianProduct ({
              k8sLabelPrefix,
              k8sLabelName,
            }: "${k8sLabelPrefix}/${k8sLabelName}") {
              k8sLabelPrefix = k8sLabelPrefix.tests.typeChecking.accepted.inputs;
              k8sLabelName = k8sLabelNames.valid;
            };
          rejected.inputs =
            []
            # every invalid k8sLabelName on its own (containing no single slash) is an invalid k8sLabel
            ++ filter (x: ! matchesRegex "^[^/]+[/][^/]+$" x) k8sLabelNames.invalid
            # every concatenation with '/' of an invalid k8sLabelPrefix and valid k8sLabelName is an invalid k8sLabel
            ++ mapCartesianProduct ({
              invalidK8sLabelPrefix,
              k8sLabelName,
            }: "${invalidK8sLabelPrefix}/${k8sLabelName}") {
              invalidK8sLabelPrefix = k8sLabelPrefix.tests.typeChecking.rejected.inputs;
              k8sLabelName = k8sLabelNames.valid;
            }
            # every concatenation with '/' of an valid k8sLabelPrefix and invalid k8sLabelName is an invalid k8sLabel
            ++ mapCartesianProduct ({
              k8sLabelPrefix,
              invalidK8sLabelName,
            }: "${k8sLabelPrefix}/${invalidK8sLabelName}") {
              k8sLabelPrefix = k8sLabelPrefix.tests.typeChecking.accepted.inputs;
              invalidK8sLabelName = k8sLabelNames.invalid;
            };

          inherit nonStringValuesRejected;
        };
      };
      k8sLabelStr = {
        target = optionTypes.k8sLabelStr;
        tests.typeChecking = {
          accepted.inputs =
            [
              "k8s-app=kube-dns"
              "app.kubernetes.io/name=snapshot-controller"
              "label-with-empty-value="
              "label/with-empty-value="
            ]
            # every concatenation with '=' of an k8sLabel and k8sLabelValue is a k8sLabel
            ++ mapCartesianProduct ({
              k8sLabel,
              k8sLabelValue,
            }: "${k8sLabel}=${k8sLabelValue}") {
              k8sLabel = k8sLabel.tests.typeChecking.accepted.inputs;
              k8sLabelValue = k8sLabelValue.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [
              ""
              " "
              "="
              "label-without-value"
              "label/without-value"
              "=value-with-empty-label"
            ]
            # every concatenation with '=' of an invalid k8sLabel and valid k8sLabelValue is an invalid k8sLabelStr
            ++ mapCartesianProduct ({
              invalidK8sLabel,
              k8sLabelValue,
            }: "${invalidK8sLabel}=${k8sLabelValue}") {
              invalidK8sLabel = k8sLabel.tests.typeChecking.rejected.inputs;
              k8sLabelValue = k8sLabelValue.tests.typeChecking.accepted.inputs;
            }
            # every concatenation with '=' of an valid k8sLabel and invalid k8sLabelValue is an invalid k8sLabel
            ++ mapCartesianProduct ({
              k8sLabel,
              invalidK8sLabelValue,
            }: "${k8sLabel}=${invalidK8sLabelValue}") {
              k8sLabel = k8sLabel.tests.typeChecking.accepted.inputs;
              invalidK8sLabelValue = k8sLabelValue.tests.typeChecking.rejected.inputs;
            };

          inherit nonStringValuesRejected;
        };
      };
      k8sLabelAttrs = {
        target = optionTypes.k8sLabelAttrs;
        tests.typeChecking = {
          accepted.inputs = [
            {}
            {"foo" = "bar";}
            {
              "k8s-app" = "kube-dns";
              "app.kubernetes.io/name" = "snapshot-controller";
              "label-with-empty-value" = "";
              "label/with-empty-value" = "";
            }
            # any mapping of an k8sLabel and k8sLabelValue is a valid k8sLabelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (name: value: {inherit name value;})
                k8sLabel.tests.typeChecking.accepted.inputs
                k8sLabelValue.tests.typeChecking.accepted.inputs
              )
            )
          ];
          rejected.inputs = [
            {"" = "foo";}
            {" " = "foo";}
            # any mapping of an invalid k8sLabel and valid k8sLabelValue is an invalid k8sLabelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (invalidK8sLabel: k8sLabelValue: {
                  name = invalidK8sLabel;
                  value = k8sLabelValue;
                })
                k8sLabel.tests.typeChecking.rejected.inputs
                k8sLabelValue.tests.typeChecking.accepted.inputs
              )
            )
            # any mapping of a valid k8sLabel and invalid k8sLabelValue is an invalid k8sLabelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (k8sLabel: invalidK8sLabelValue: {
                  name = k8sLabel;
                  value = invalidK8sLabelValue;
                })
                k8sLabel.tests.typeChecking.accepted.inputs
                k8sLabelValue.tests.typeChecking.rejected.inputs
              )
            )
            # any mapping of an invalid k8sLabel and invalid k8sLabelValue is an invalid k8sLabelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (invalidK8sLabel: invalidK8sLabelValue: {
                  name = invalidK8sLabel;
                  value = invalidK8sLabelValue;
                })
                k8sLabel.tests.typeChecking.rejected.inputs
                k8sLabelValue.tests.typeChecking.rejected.inputs
              )
            )
          ];

          inherit nonAttrsValuesRejected;
        };
      };
      k8sTaintStr = {
        target = optionTypes.k8sTaintStr;
        tests.typeChecking = {
          accepted.inputs =
            [
              "node-role.kubernetes.io/control-plane:NoSchedule"
              "foo=bar:NoExecute"
              "foo=:PreferNoSchedule"
            ]
            # every concatenation of a k8sLabel, k8sLabelValue and taintEffect is a k8sTaintStr
            ++ mapCartesianProduct ({
              k8sLabel,
              k8sLabelValue,
              k8sTaintEffect,
            }: "${k8sLabel}=${k8sLabelValue}:${k8sTaintEffect}") {
              k8sLabel = k8sLabel.tests.typeChecking.accepted.inputs;
              k8sLabelValue = k8sLabelValue.tests.typeChecking.accepted.inputs;
              k8sTaintEffect = ["NoExecute" "NoSchedule" "PreferNoSchedule"];
            };
          # NOTE: Not adding the concatenations of k8sLabel, k8sLabelValue and k8sTaintEffect here because this results in a huge amount of items
          rejected.inputs = [
            ""
            " "
            "taint-without-effect="
            "taint-with-empty-effect=value:"
            "=value-without-name-and-effect"
          ];

          inherit nonStringValuesRejected;
        };
      };
      k8sDurationStr = {
        target = optionTypes.k8sDurationStr;
        tests.typeChecking = {
          accepted.inputs = [
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms3ns"
            "45m34h55s"
            "40h7s"
            "19272936413s"
          ];
          rejected.inputs = [
            ""
            "12"
            "01s"
            "45mm"
            "-5m"
            "m"
            "8d5h"
          ];
          inherit nonStringValuesRejected;
        };
      };
      k8sImageRef = {
        target = optionTypes.k8sImageRef;
        tests.typeChecking = {
          accepted.inputs = [
            "quay.io/calico/apiserver:v3.28.1"
            "quay.io/calico/apiserver@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "quay.io/calico/apiserver:v3.28.1@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "foo"
            "foo/bar"
            "foo:latest"
            "foo/bar:latest"
          ];
          rejected.inputs = [
            ""
            "quay.io/calico/"
            "quay.io/calico/apiserver@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf:v3.28.1"
            "quay.io/calico/apiserver@SHA256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "_foo"
          ];
          inherit nonStringValuesRejected;
        };
      };

      helmChartRepoUrl = {
        target = optionTypes.helmChartRepoUrl;
        # helmChartRepoUrl is an alias of httpxUrl
        tests.typeChecking = httpxUrl.tests.typeChecking;
      };
      helmChartReleaseName = {
        target = optionTypes.helmChartReleaseName;
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
      helmChartVersion = {
        target = optionTypes.helmChartVersion;
        # helmChartVersion is a union of semver2VersionStr and ociImageTag
        tests.typeChecking = {
          semver2Accepted.inputs = semver2VersionStr.tests.typeChecking.accepted.inputs;
          ociImageTagAccepted.inputs = ociImageTag.tests.typeChecking.accepted.inputs;
          # ociImageTag is a superset of semver2VersionStr therefore we can simply reuse the value it rejects
          inherit (ociImageTag.tests.typeChecking) rejected;
          inherit nonStringValuesRejected;
        };
      };
      helmChartRef = {
        target = optionTypes.helmChartRef;
        # helmChartRef is equal to relativeUrlPath
        tests.typeChecking = relativeUrlPath.tests.typeChecking;
      };

      terraformDurationStr = {
        target = optionTypes.terraformDurationStr;
        tests.typeChecking = {
          accepted.inputs = [
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms3ns"
            "45m34h55s"
            "40h7s"
            "19272936413s"
          ];
          rejected.inputs = [
            ""
            "12"
            "01s"
            "45mm"
            "-5m"
            "m"
            "8d5h"
          ];
          inherit nonStringValuesRejected;
        };
      };

      base64Str = {
        target = optionTypes.base64Str;
        tests.typeChecking = {
          accepted.inputs = [
            "6BK8itgi30zEqwe3RpPnRje0nkB8OJ3+lOxsUmfzqnA="
            "VGFyb29r"
            "eWFvb2s="
            "8J+aoiBGdWxsIGxpZmUtY3ljbGUgbWFuYWdlbWVudCBvZiBLdWJlcm5ldGVzIGNsdXN0ZXJzIHJ1bm5pbmcgb24gYmFyZSBtZXRhbCBvciBPcGVuU3RhY2su"
            "IA=="
          ];
          rejected.inputs = [
            ""
            "IA="
            "4rdHFh%2BHYoS8oLdVvbUzEVqB8Lvm7kSPnuwF0AAABYQ%3D"
            "++"
            "VGFyb29r=="
          ];
          inherit nonStringValuesRejected;
        };
      };
      wireguardKey = {
        target = optionTypes.wireguardKey;
        tests.typeChecking = {
          accepted.inputs = [
            "AELw/sSLVdd+V1A8sVDyA2nHk8nJXCYgKLwlPvQKuGo="
            "eDaj+ysRCXFNYfoHZL58VRr+tSfRQVj6L+mfwJrOGH4="
            "aBWORk469SnonqPSO31ZTo3EDCtmcZPs1AOsjYQTdE0="
            "EPtKEwRYflRsrqMHURfpRz38Gl+KebY0rUKaVjOCC0w="
          ];
          rejected.inputs =
            [
              ""
              "VGFyb29r"
              "AELw/sSLVdd+valid+base64+but+48+chars+aamx1Aad3f"
              "nxq7+base64+but+40+chars+8mrz09dxnq84y1a"
            ]
            # wireguardKey is a subset of base64Str
            ++ base64Str.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };

      prometheusIntervalStr = {
        target = optionTypes.prometheusIntervalStr;
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
      prometheusLabelName = {
        target = optionTypes.prometheusLabelName;
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
      prometheusTimeoutStr = {
        target = optionTypes.prometheusTimeoutStr;
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
      prometheusRelabelConfig = {
        target = optionTypes.prometheusRelabelConfig;
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

      s3BucketName = {
        target = optionTypes.s3BucketName;
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
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  # Run tests and return boolean outcome + trace runTests output on failure
  let
    outcome = runTests (mkRunTests optionTypeUnitTests);
  in (
    if outcome == []
    then true
    else lib.debug.traceSeq outcome false
  )
