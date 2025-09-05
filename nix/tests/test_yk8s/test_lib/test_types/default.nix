{
  yk8s-test-lib,
  ctx,
  lib,
  ...
}: let
  inherit (yk8s-test-lib) filePrefix;
  testFiles = let
    isTestFile = filename: (builtins.match "${filePrefix}.*" filename) != null;
  in
    lib.pipe ./. [
      builtins.readDir
      builtins.attrNames
      (builtins.filter (filename: isTestFile filename))
    ];
  files = let
    excludeList = [
      "default.nix"
    ];
    isExcludedFromTesting = filename: ! builtins.elem filename excludeList;
  in
    lib.pipe ctx.importPath [
      builtins.readDir
      builtins.attrNames
      (lib.filter (filename: isExcludedFromTesting filename))
      (builtins.map (filename: "${filePrefix}${filename}"))
    ];
  missingTestFiles = lib.subtractLists testFiles files;
in
  (
    ctx.evaluator {
      inherit yk8s-test-lib;
      inherit (ctx) importPath;
      self = ctx.evaluator;
      path = ./.;
    }
  ) && (
    # Enforce that our set of test file is complete
    lib.traceIf
      (missingTestFiles != [])
      (lib.concatStrings [
        "All files in ${toString ctx.importPath}"
        " must have a corresponding test file in ${toString ./.}"
        ", but the following are missing: "
        (lib.strings.concatMapStringsSep ", " (x: "'${x}'") missingTestFiles)
      ])
      (missingTestFiles == [])
  )
