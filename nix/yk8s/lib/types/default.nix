{lib}: let
  # Import all other files in the directory (except _toplevel.nix) into
  # an attribute set where attribute name corresponds to filename with suffix removed
  nestedTypes = lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (filename: _: lib.hasSuffix ".nix" filename))
    (lib.filterAttrs (filename: _: ! builtins.elem filename ["default.nix" "_toplevel.nix"]))
    (lib.mapAttrs' (filename: _: {
      name = lib.removeSuffix ".nix" filename;
      value = filename;
    }))
    (lib.mapAttrs (_: filename: (import (./. + "/${filename}")) {inherit lib;}))
  ];
  toplevel = import ./_toplevel.nix {inherit lib;};
in
  # Expose an updated version of nixpkgs's `lib.types` that contains our types as a
  # nested attribute set under `types.yk8s`
  lib.types // {yk8s = nestedTypes // toplevel;}
