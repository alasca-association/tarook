{
  flake-parts-lib,
  inputs,
  ...
}: {


  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        config,
        lib,
        system,
        ...
      }: {
        config = {
          packages = (
            lib.mapAttrs' (name: env: {
              name = "sbom-${name}";
              value = inputs.bombon.lib.${system}.buildBom env {};
            })
            config.yk8s-env.environments
          );
        };
      }
    );
  };
}
