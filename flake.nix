{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.systems.url = "github:nix-systems/x86_64-linux/2ecfcac5e15790ba6ce360ceccddb15ad16d08a8";
  inputs.terranix.url = "github:terranix/terranix";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import inputs.systems;
      debug = true;
      imports = [
        ./nix/renderDocs.nix
        ./nix/yk8s-env.nix
        ./ci/container-image
      ];
      perSystem = {
        pkgs,
        lib,
        system,
        inputs',
        config,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
        };
        imports = [
          ./nix/test.nix
        ];
        packages = {
          init = pkgs.writeShellApplication {
            name = "init-cluster-repo";
            runtimeInputs = with pkgs; [
              rsync
              git
            ];
            text = ''
              exec ${self}/actions/init-cluster-repo.sh "$@"
            '';
          };
          alejandra-tree = pkgs.writeShellApplication {
            name = "alejandra-tree";
            runtimeInputs = [pkgs.alejandra];
            text = ''
              if [[ $# -eq 0 ]]; then
                exec alejandra .
              else
                exec alejandra "$@"
              fi
            '';
          };
        };
        formatter = self.packages.${system}.alejandra-tree;
      };
      flake = {lib, ...}: {
        flakeModules.yk8s = import ./nix/yk8s;
      };
    };
}
