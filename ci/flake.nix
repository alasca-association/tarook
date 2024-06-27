{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.yk8s.url = "git+file:managed-k8s?shallow=1";

  outputs = inputs @ {
    self,
    yk8s,
    ...
  }:
    yk8s.inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.yk8s.flakeModules.yk8s
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      debug = true;
      perSystem = {
        pkgs,
        lib,
        config,
        ...
      }: {
        formatter = pkgs.alejandra;
        yk8s =
          import ./config {
            inherit pkgs lib config;
            yk8s-lib = inputs.yk8s.lib;
          }
          // {
            # Don't change this except you know what you're doing
            state_directory =
              if builtins.pathExists ./state
              then ./state
              else null;
          };
      };
    };
}
