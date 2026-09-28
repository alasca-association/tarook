{
  flake-parts-lib, 
  ...
}: {


  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        config,
        lib,
        system,
        bombon,
        ...
      }: {
        config = {
          packages = lib.mkIf (system == "x86_64-linux") {
            sbom-default = bombon.lib.${system}.buildBom config.yk8s-env.environments.default {};
            sbom-minimal = bombon.lib.${system}.buildBom config.yk8s-env.environments.minimal {};
            sbom-dev = bombon.lib.${system}.buildBom config.yk8s-env.environments.dev {};
            sbom-ci = bombon.lib.${system}.buildBom config.yk8s-env.environments.ci {};
            sbom-docs = bombon.lib.${system}.buildBom config.yk8s-env.environments.docs {};
            sbom-lint = bombon.lib.${system}.buildBom config.yk8s-env.environments.lint {};
          };
        };
      }
    );
  };
}
