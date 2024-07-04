{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }: let
    dependencies = pkgs:
      with pkgs; {
        yk8s = [
          coreutils
          gcc # so poetry can build netifaces
          git
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
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      debug = true;
      perSystem = {
        pkgs,
        system,
        inputs',
        config,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.outputs.lib.getName pkg) [
              "terraform"
              "vault"
            ];
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = (dependencies pkgs).interactive;
          buildInputs = (dependencies pkgs).yk8s;
        };
        packages = let
          container-image = import ./ci/container-image {inherit pkgs dependencies;};
        in {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
          init = pkgs.writeShellApplication {
            name = "init-cluster-repo";
            runtimeInputs = (dependencies pkgs).yk8s;
            text = ''
              ${./.}/actions/init-cluster-repo.sh
            '';
          };
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
        flakeModules.yk8s = import ./nix/module {inherit dependencies;};
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
