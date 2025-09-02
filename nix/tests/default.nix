{
  lib,
  importPath,
}: let
  # Directory that contains the tests
  testsDir = ./.;

  # Name prefix of test files and directories
  # (only those get evaluated)
  filePrefix = "test_";

  /*
  Run all the tests contained in a directory

  Returns the outcome as a boolean where `true` means success and `false` failure.
  Trace-outputs the files that are being evaluated and their individual outcomes.

  Searches for test files and directories in the given path
  and imports them with the following argument set:

    {
      lib,              # Nixpkgs library or equal
      yk8s-test-lib,    # The yk8s test library
      ctx = {           # Test context
        evaluator,      # Test evaluator function (the importer itself)
        importPath      # The importPath of the importer extended
                        #  with the unprefixed name of the imported file or directory,
                        #  e.g. importer.importPath = ./lorem;
                        #       imported.name = ./tests/test_lorem/test_ipsum.nix;
                        #       -> imported.importPath = ./lorem/ipsum.nix;
      },
      extra ? {}        # Optional attrset for passing extra arguments
    }

  A test file or directory needs to yield a boolean which determines the test's outcome.

  Arguments (attrset):
    - self: This function
    - yk8s-test-lib: Attrset holding the yk8s test library
    - path: The directory path to search for tests
    - importPath: The path from where tests should import their target, e.g. ./nix/yk8s/lib/types
    - extra: Optional attrset with additional data or functions
  */
  evalTests = {
    self,
    yk8s-test-lib,
    path,
    importPath,
    extra ? {},
  }: let
    inherit (builtins) baseNameOf isBool toString;
    inherit (lib.trivial) boolToString;
    inherit (lib.debug) traceSeq;
    inherit (yk8s-test-lib) getTestFiles;
    testFilePrefix = yk8s-test-lib.filePrefix;

    # Run each collected test file or directory
    results = builtins.map (
      file: let
        # Import test file or directory
        #  passing it lib, yk8s-test-lib, test context, a test evaluator and optional extra arguments
        test_output = import file.path {
          inherit lib yk8s-test-lib extra;
          ctx = {
            evaluator = self;
            importPath =
              importPath
              + "/${lib.removePrefix testFilePrefix (baseNameOf file.path)}";
          };
        };
        # Set boolean outcome
        # (tests need to return booleans, if they don't they are deemed to have failed)
        outcome =
          if (isBool test_output)
          then test_output
          else false;
      in
        traceSeq "Evaluating ${toString file.path} ..."
        {
          outcome =
            traceSeq "Outcome: ${toString file.path}: ${boolToString outcome}${
              if outcome != test_output
              then " (invalid output)"
              else ""
            }"
            outcome;
        }
      # collect test files and directories
    ) (getTestFiles path);

    forcedResults = builtins.deepSeq results results; # force complete evaluation
  in
    # NOTE: Completely evaluate all tests first then accumulate results
    #       so that the evaluation is not stopped by a negative result
    #       and all of them are traced
    # Accumulate test boolean outcomes
    builtins.all (r: r.outcome) forcedResults;

  yk8s-test-lib = rec {
    inherit
      filePrefix
      evalTests
      ;

    /*
    Select files from a given file path whose type is one of the given ones

    Arguments:
      - types: A list of file types (types as output by `builtins.readDir`)
      - path: A path
    */
    selectFilesByType = types: path:
      lib.filterAttrs
      (_: fileType: builtins.elem fileType types)
      (builtins.readDir path);

    /*
    List all test files in a directory

    Returns a list of attrsets where the 'path' attribute contains a file path
    and the 'type' attribute is set to either "regular" or "directory".

    Arguments:
      - path: The directory's path
    */
    getTestFiles = path:
      lib.attrsets.mapAttrsToList
      (file: type: {
        path = path + "/${file}";
        type = type;
      })
      (
        lib.filterAttrs
        (name: _: lib.strings.hasPrefix filePrefix name)
        (selectFilesByType ["regular" "directory"] path)
      );
  };
in
  evalTests {
    inherit yk8s-test-lib importPath;
    self = evalTests;
    path = testsDir;
  }
