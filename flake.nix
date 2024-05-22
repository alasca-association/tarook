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
      imports = [
        ./module.nix
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
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
          nativeBuildInputs = [pkgs.bashInteractive];
          buildInputs = [
            pkgs.openstackclient
            pkgs.k9s
            pkgs.kubernetes-helm
            pkgs.kubectl
            pkgs.jq
            pkgs.moreutils
            pkgs.terraform
            pkgs.vault
            pkgs.openssl
            pkgs.wireguard-tools
            pkgs.poetry
          ];
        };

        formatter = pkgs.alejandra;
      };
    };
}
