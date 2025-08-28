{
  inputs.yk8s.url = "git+https://gitlab.com/alasca.cloud/tarook/tarook";
  inputs.nixpkgs.follows = "yk8s/nixpkgs";
  inputs.flake-parts.follows = "yk8s/flake-parts";

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.yk8s.flakeModules.yk8s
      ];
      systems = ["x86_64-linux"];
      debug = true;
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        imports = [./config];

        # Don't change this except you know what you're doing
        yk8s.state_directory =
          if builtins.pathExists ./state
          then ./state
          else null;
      };
    };
}
