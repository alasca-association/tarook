{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # pin poetry 1.3.2
  # TODO: keep version in sync with CI image
  inputs.nixpkgs-poetry.url = "github:NixOS/nixpkgs/8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8";

  outputs = { self, nixpkgs, flake-utils, nixpkgs-poetry, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      poetry_v1_3_2 = nixpkgs-poetry.legacyPackages.${system}.poetry;
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [
          pkgs.openstackclient
          pkgs.k9s
          pkgs.kubernetes-helm
          pkgs.kubectl
          pkgs.jq
          pkgs.moreutils
          pkgs.jsonnet
          pkgs.terraform
          pkgs.vault
          pkgs.openssl
          pkgs.wireguard-tools
          # poetry_v1_3_2
          pkgs.poetry
        ];
      };
    });
}
