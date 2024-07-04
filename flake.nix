{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      perSystem = {
        pkgs,
        system,
        inputs',
        config,
        ...
      }: let
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
            openstackclient
            poetry
            terraform
            util-linux # for uuidgen
            vault
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
            vim
            dnsutils
            iputils
            k9s
            curl
          ];
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.outputs.lib.getName pkg) [
              "terraform"
              "vault"
            ];
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = dependencies.interactive;
          buildInputs = dependencies.yk8s;
        };
        packages = let
          container-image = import ./ci/container-image {inherit pkgs dependencies;};
        in {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
          migrate = pkgs.writeShellApplication {
            name = "migrate-cluster-repo";
            runtimeInputs = with pkgs; [];
            text = ''
              nix flake init -t ./managed-k8s#migration
              git add flake.nix config/default.nix
              nix run .#update-inventory
            '';
          };
        };
        formatter = pkgs.alejandra;
      };
      flake = {lib, ...}: {
        flakeModules.yk8s = import ./nix/module;
        lib = import ./nix/lib.nix {inherit lib;};
        templates.cluster-repo = {
          description = ''
            Template containing all the Nix parts of the cluster repo
          '';
          path = ./nix/templates/cluster-repo;
        };
        templates.migration = {
          # TODO generate
          # TODO add version
          description = ''
            Template to migrate from before vX.0.0
          '';
          path = ./nix/templates/migration;
        };
      };
    };
}
