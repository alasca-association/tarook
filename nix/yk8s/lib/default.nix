{
  lib,
  pkgs,
  ...
}: rec {
  options = import ./options.nix {inherit lib;};
  types = import ./types.nix {inherit lib;};
  transform = import ./transform.nix {inherit lib;};

  inherit
    (options)
    mkInternalOption
    mkTopSection
    mkSubSection
    mkResourceOption
    mkMultiResourceOptions
    ;

  mkGroupVarsFile = {
    cfg,
    inventory_path,
    ansible_prefix ? "",
    only_if_enabled ? false,
    transformations ? [],
    unflat ? [],
  }: let
    inherit (lib.trivial) pipe;
    inherit (pkgs.stdenv) mkDerivation;
    path = "group_vars/${inventory_path}";
    finalConfig = let
      t = transform;
    in
      pipe cfg (
        (lib.optional only_if_enabled t.onlyIfEnabled)
        ++ [t.removeObsoleteOptions t.filterInternal]
        ++ transformations
        ++ [
          (t.flatten {except = cfg._internal.unflat ++ unflat;})
          (t.addPrefix ansible_prefix)
          t.filterNull
        ]
      );
  in
    mkDerivation {
      name = "yaook-k8s-" + path;
      src = ./.;
      allowSubstitutes = false;
      preferLocalBuild = true;
      buildPhase = builtins.traceVerbose "Writing file: ${path}" ''
        install -m 644 -D ${mkYaml path finalConfig} $out/${path}
      '';
    };
  mkYaml = (pkgs.formats.yaml {}).generate;
  linkToPath = file: path:
    pkgs.runCommandLocal path {
      allowSubstitutes = false;
      preferLocalBuild = true;
    } ''
      mkdir -p $(dirname $out/${path})
      ln -s ${file} $out/${path}
    '';

  baseSystemAssertWarn = {
    assertions,
    warnings,
    ...
  }: let
    inherit (builtins) map filter concatStringsSep trace;
    inherit (lib) showWarnings;
    failedAssertions = map (x: x.message) (filter (x: !x.assertion) assertions);
  in
    if failedAssertions != []
    then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings warnings "";
}
