{pkgs, ...}: {
  packages = rec {
    tarook = pkgs.callPackage ./tarook.nix {};
    tarook-dev = tarook.overridePythonAttrs (old: {
      dependencies =
        (old.dependencies or [])
        ++ (with tarook.passthru.python3.pkgs; [
          jedi-language-server
        ]);
    });
  };
}
