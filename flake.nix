{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        lib,
        system,
        inputs',
        ...
      }: let
        poetryEnvs = import ./nix/poetry.nix {
          inherit pkgs lib;
          inherit (inputs) poetry2nix;
        };
        dependencies = with pkgs; {
          yk8s = [
            coreutils
            gcc # so poetry can build netifaces
            gnugrep
            gnused
            gzip
            iproute2 # for wg-up
            jq
            kubectl
            kubernetes-helm
            moreutils
            openssh
            openssl
            poetry
            inputs'.nixpkgs-terraform157.legacyPackages.terraform
            util-linux # for uuidgen
            inputs'.nixpkgs-vault1148.legacyPackages.vault
            wireguard-tools
          ];
          ci = [
            direnv
            git
            gnupg
            gnutar
            netcat
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
        };
        formatter = pkgs.alejandra;
      };
    };
}
