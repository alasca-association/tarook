{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.outputs.lib.getName pkg) [
            "vault"
          ];
      };
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [pkgs.bashInteractive];
        buildInputs = [
          pkgs.openstackclient
          pkgs.k9s
          pkgs.kubernetes-helm
          pkgs.kubectl
          pkgs.jq
          pkgs.moreutils
          pkgs.opentofu
          pkgs.vault
          pkgs.openssl
          pkgs.wireguard-tools
          pkgs.poetry
        ];
      };

      formatter = pkgs.alejandra;
    });
}
