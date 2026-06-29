{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s._pythonIFD;
  inherit (yk8s-lib) types;
in {
  options.yk8s._pythonIFD = {
    functions = yk8s-lib.mkInternalOption {
      type = types.attrsOf (types.submodule {
        options = {
          body = lib.mkOption {
            description = ''
              Body of a Python function that will be called with ``arg`` as a single argument.
              Return value will be available at ``config.yk8s._pythonIFD.outputs.<functionName>``
            '';
            type = types.nonEmptyStr;
            example = ''
              if arg == "foo":
                return "bar"
              elif arg == []:
                return "bar"
              else:
                return "foobar"
            '';
          };
          arg = lib.mkOption {
            description = ''
              Available inside the body as ``arg``.
            '';
            type = types.yk8s.formats.jsonValue;
            example = "foo";
          };
        };
      });
    };
    outputs = yk8s-lib.mkInternalOption {
      readOnly = true;
      type = with types; attrsOf yk8s.formats.jsonValue;
    };
  };
  config.yk8s.assertions =
    lib.mapAttrsToList (n: _: {
      assertion = yk8s-lib.transform.matchesRegex "[a-zA-Z_][a-zA-Z0-9_]*" n;
      message = "config.yk8s._pythonIFD: ${n} is not a valid Python function name. Function names must adhere to the regex '[a-zA-Z_][a-zA-Z0-9_]*'";
    })
    cfg.functions;
  config.yk8s._pythonIFD.outputs = let
    indent4 = yk8s-lib.transform.indent 4;
    functions = lib.pipe cfg.functions [
      (lib.mapAttrsToList (n: v: ''
        def ${n}(arg):
        ${indent4 v.body}
      ''))
      lib.concatLines
    ];
    functionCalls = lib.pipe cfg.functions [
      lib.attrNames
      (map (f: ''
        result["${f}"] = ${f}(inputs["${f}"])
      ''))
      lib.concatLines
    ];
    script = builtins.toFile "pythonIFD.py" ''
      #!/usr/bin/env python3
      import os, json

      ${functions}

      if __name__ == "__main__":
          json_file = os.environ["NIX_ATTRS_JSON_FILE"]
          with open(json_file, "r") as f:
              inputs = json.load(f)["inputs"]

          result = {}
          ${functionCalls}

          out = os.environ["out"]
          with open(out, "w") as f:
              json.dump(result, f)
    '';
    result =
      pkgs.runCommandLocal "pythonIFDResult.json" {
        nativeBuildInputs = [pkgs.python3];
        __structuredAttrs = true;
        inputs = (lib.mapAttrs (_: v: v.arg)) cfg.functions;
      } ''
        exec python3 ${script}
      '';
  in
    builtins.traceVerbose "yk8s._pythonIFD: script = ${script}"
    builtins.traceVerbose "yk8s._pythonIFD: result = ${result}"
    builtins.fromJSON (builtins.readFile result);
}
