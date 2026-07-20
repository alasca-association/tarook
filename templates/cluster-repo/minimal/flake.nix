{
  inputs.yk8s.url = "git+https://gitlab.com/alasca.cloud/tarook/tarook";
  inputs.nixpkgs.follows = "yk8s/nixpkgs";
  inputs.flake-parts.follows = "yk8s/flake-parts";
  inputs.systems.url = "github:nix-systems/x86_64-linux/2ecfcac5e15790ba6ce360ceccddb15ad16d08a8";

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.yk8s.flakeModules.yk8s
      ];
      systems = import inputs.systems;
      debug = true;
      perSystem = {
        system,
        pkgs,
        ...
      }: {
        formatter = inputs.yk8s.packages.${system}.alejandra-tree;
        imports = [./config];
      };
    };
}
