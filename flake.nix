{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-terraform157.url = "github:NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
  inputs.nixpkgs-vault1148.url = "github:NixOS/nixpkgs/7cf8d6878561e8b2e4b1186f79f1c0e66963bdac";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig.extra-substituters = [
    "https://yaook.cachix.org"
  ];
  nixConfig.extra-trusted-public-keys = [
    "yaook.cachix.org-1:m85JtxgDjaNa7hcNUB6Vc/BTxpK5qRCqF4yHoAniwjQ="
  ];

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
        inherit (inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryEnv overrides;
        poetryEnv = mkPoetryEnv {
          projectDir = ./.;
          groups = ["ci"];
          overrides = overrides.withDefaults (final: prev:
            lib.attrsets.mapAttrs (n: v:
              prev.${n}.overridePythonAttrs (old: {
                nativeBuildInputs =
                  old.nativeBuildInputs
                  or []
                  ++ map (p: pkgs.python312Packages.${p}) v;
              }))
            {
              os-client-config = ["setuptools"];
              kubernetes-validate = ["setuptools"];
              sphinx-multiversion = ["setuptools"];
            });
          python = pkgs.python312;
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
            poetryEnv
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
        };
        devShells.default = pkgs.mkShell {
          buildInputs = dependencies.yk8s;
        };
        devShells.withInteractive = pkgs.mkShell {
          nativeBuildInputs = dependencies.interactive;
          buildInputs = dependencies.yk8s;
        };
        devShells.poetry = poetryEnv.env;
        packages = let
          container-image = import ./ci/container-image {inherit pkgs dependencies;};
        in {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
        };
        formatter = pkgs.alejandra;
      };
    };
}
