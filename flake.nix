{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
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
        packages = let
          container-image = import ./ci/container-image {
            inherit lib pkgs;
            inherit (config.packages) yk8s-env-ci;
          };
        in {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
          renderDocs = pkgs.writeShellApplication {
            name = "render-docs";
            text = ''
              out=$(nix build --print-out-paths --no-link .#docsRST)
              rsync -rL --delete --chmod 664 "$out/" docs/user/reference/options
              python3 -m sphinx docs _build/html -E
            '';
          };
          init = pkgs.writeShellApplication {
            name = "init-cluster-repo";
            runtimeInputs = config.packages.yk8s-env-main;
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
        lib = import ./nix/lib.nix {inherit lib;};
        templates.cluster-repo = {
          description = ''
            Template containing all the Nix parts of the cluster repo
          '';
          path = ./nix/templates/cluster-repo;
        };
        templates.migration = {
          description = ''
            Template to migrate from before vX.0.0
          '';
          path = ./nix/templates/migration;
        };
      };
    };
}
