{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      debug = true;
      imports = [
        ./nix/renderDocs.nix
        ./nix/yk8s-env.nix
        ./nix/templates
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
            runtimeInputs = [config.yk8s-env.environments.default];
            text = ''
              if [[ -n "''${1:-""}" ]]; then
                export MANAGED_K8S_LATEST_RELEASE=false
                export MANAGED_K8S_GIT_BRANCH="$1"
              fi
              ${./.}/actions/init-cluster-repo.sh
            '';
          };
        };
        formatter = pkgs.alejandra;
      };
      flake = {lib, ...}: {
        flakeModules.yk8s = import ./nix/yk8s;
      };
    };
}
