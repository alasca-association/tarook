{
  lib,
  ctx,
  ...
}: rec {
  inherit (lib) runTests;
  yk8s-lib.transform = import (ctx.importPath + "/../../transform.nix") {inherit lib;};

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
      == length (mapAttrsToList (_: target: target) (lib.filterAttrs (n: _: ! lib.hasPrefix "_" n) testSuite.meta.targets))
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

  mkPassthruTest = optionTypeUnitTests: let
    outcome = runTests (mkRunTests optionTypeUnitTests);
  in {
    result = (
      # Return boolean outcome from `runTests` run + trace runTests output on failure
      if outcome == []
      then true
      else lib.debug.traceSeq outcome false
    );
    passthru.testSuite = optionTypeUnitTests;
  };

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
    lib.filter (x: (builtins.stringLength x) <= maxLength);

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

    rfc9293PortNumbers = {
      valid = [0 1 443 8080 35000 65535];
      invalid = [(-1) (-3462) 65536 80000];
    };
  };
}
