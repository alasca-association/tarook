{
  pkgs,
  lib,
  poetry2nix,
}: let
  inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryEnv overrides;
  poetryEnvWithGroups = groups:
    mkPoetryEnv {
      projectDir = ./..;
      inherit groups;
      overrides = overrides.withDefaults (final: prev: let
        rm.lists = lists: old: builtins.mapAttrs (name: value: lib.subtractLists value old."${name}") lists;
        modified = pkg: fns: pkg.overridePythonAttrs (oldAttrs: lib.pipe oldAttrs (builtins.map (fn: entry: entry // (fn entry)) fns));
      in
        (builtins.mapAttrs (name: modified prev."${name}") {
          pynacl = [
            (rm.lists {nativeBuildInputs = with final; [sphinxHook];})
            (rm.lists {outputs = ["doc"];})
          ];
          pyjwt = [
            (rm.lists {nativeBuildInputs = with final; [sphinxHook sphinx-rtd-theme];})
            (rm.lists {outputs = ["doc"];})
          ];
        })
        // (builtins.mapAttrs (n: v:
            prev.${n}.overridePythonAttrs (old: {
              nativeBuildInputs =
                old.nativeBuildInputs
                or []
                ++ map (p: pkgs.python312Packages.${p}) v;
            }))
          {
            os-client-config = ["setuptools"];
            kubernetes-validate = ["setuptools"];
            sphinx-multiversion = ["setuptools"];
          }));
      python = pkgs.python312;
    };
in {
  minimal = poetryEnvWithGroups ["minimal-access"];
  yk8s = poetryEnvWithGroups [
    "main"
    "offline-installation"
    "minimal-access"
  ];
  ci = poetryEnvWithGroups [
    "main"
    "ci"
    "offline-installation"
    "minimal-access"
  ];
}
