{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # pin poetry 1.3.2
  # TODO: keep version in sync with CI image
  inputs.nixpkgs-poetry.url = "github:NixOS/nixpkgs/8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8";
  inputs.krew2nix.url = "github:Lykos153/krew2nix";
  inputs.krew2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, flake-utils, nixpkgs-poetry, krew2nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
                (final: prev: {
                    kubectl = krew2nix.outputs.packages.${system}.kubectl;
                })

        ];
      };
      poetry_v1_3_2 = nixpkgs-poetry.legacyPackages.${system}.poetry;
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [
          pkgs.openstackclient
          pkgs.k9s
          pkgs.kubernetes-helm
          (pkgs.kubectl.withKrewPlugins (plugins: with plugins; [
            node-shell
            get-all
            example
            rook-ceph
          ]))
          pkgs.jq
          pkgs.moreutils
          pkgs.jsonnet
          pkgs.jsonnet-bundler
          pkgs.terraform
          pkgs.vault
          pkgs.openssl
          pkgs.wireguard-tools
          # poetry_v1_3_2
          pkgs.poetry
          pkgs.mob
        ];
      };
    });
}
