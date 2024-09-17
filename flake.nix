{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.terranix.url = "github:terranix/terranix";

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
      ];
      perSystem = {
        pkgs,
        lib,
        system,
        inputs',
        config,
        ...
      }: let
        poetryEnvs = import ./nix/poetry.nix {
          inherit pkgs lib;
          inherit (inputs) poetry2nix;
        };
        dependencies = with pkgs; let
          yk8s-minimal = [
            jq
            kubectl
            rsync
            inputs'.nixpkgs-vault1148.legacyPackages.vault
          ];
        in {
          inherit yk8s-minimal;
          yk8s =
            yk8s-minimal
            ++ [
              coreutils
              gcc # so poetry can build netifaces
              gnugrep
              gnused
              gzip
              iproute2 # for wg-up
              kubernetes-helm
              moreutils
              openssh
              openssl
              poetry
              inputs'.nixpkgs-terraform157.legacyPackages.terraform
              util-linux # for uuidgen
              wireguard-tools
            ];
          ci = [
            direnv
            git
            gnupg
            gnutar
            netcat
            nix
            sonobuoy
          ];
          interactive = [
            bashInteractive
            curl
            vim
            dnsutils
            iputils
            k9s
          ];
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = dependencies.yk8s ++ [poetryEnvs.yk8s];
        };
        devShells.minimal = pkgs.mkShell {
          buildInputs = dependencies.yk8s-minimal ++ [poetryEnvs.minimal];
        };
        devShells.withInteractive = pkgs.mkShell {
          nativeBuildInputs = dependencies.interactive;
          buildInputs = dependencies.yk8s ++ [poetryEnvs.yk8s];
        };
        devShells.poetry = poetryEnvs.yk8s.env;
        packages = let
          container-image = import ./ci/container-image {inherit pkgs dependencies poetryEnvs;};
        in {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
          renderDocs = pkgs.writeShellApplication {
            name = "render-docs";
            text = ''
              nix build .#docsRST -o docs/user/reference/options
              python3 -m sphinx docs _build/html -E
            '';
          };
          init = pkgs.writeShellApplication {
            name = "init-cluster-repo";
            runtimeInputs = dependencies.yk8s;
            text = ''
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
