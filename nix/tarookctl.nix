{
  inputs,
  flake-parts-lib,
  ...
}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        self',
        pkgs,
        ...
      }: let
        crane = inputs.crane;

        craneLib = crane.mkLib pkgs;

        commonArgs = {
          src = craneLib.cleanCargoSource ./../tarookctl;
          strictDeps = true;

          buildInputs = [
          ];
        };

        tarookctl = craneLib.buildPackage (
          commonArgs
          // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;

            # Additional environment variables or build phases/hooks can be set
            # here *without* rebuilding all dependency crates
            # MY_CUSTOM_VAR = "some value";
          }
        );
      in {
        checks = {
          inherit tarookctl;
        };

        packages = {
          inherit tarookctl;
          default = tarookctl;
        };

        devShells.tarookctl = craneLib.devShell {
          checks = self'.checks;

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages = [
            # pkgs.ripgrep
          ];
        };
      });
  };
}
