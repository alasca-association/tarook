{
  inputs.nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-26.05";
  inputs.nixpkgs-terraform157.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&rev=39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&rev=7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.nixpkgs-unstable.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
  inputs.flake-parts.url = "git+https://github.com/hercules-ci/flake-parts?shallow=1";
  inputs.systems.url = "git+https://github.com/nix-systems/x86_64-linux?shallow=1&rev=2ecfcac5e15790ba6ce360ceccddb15ad16d08a8";
  inputs.terranix.url = "git+https://github.com/terranix/terranix?shallow=1";

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
              findutils
              git
              rsync
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
