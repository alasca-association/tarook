{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        system,
        inputs',
        ...
      }: let
        nix2containerPkgs = inputs'.nix2container.packages;
        yk8sDeps = with pkgs; [
          openstackclient
          k9s
          kubernetes-helm
          kubectl
          jq
          moreutils
          jsonnet
          jsonnet-bundler
          terraform
          vault
          openssl
          wireguard-tools
          poetry
        ];
        interactiveDeps = with pkgs; [
          bashInteractive
          coreutils
        ];
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
          nativeBuildInputs = interactiveDeps;
          buildInputs = yk8sDeps;
        };
        packages.ciImage =
          nix2containerPkgs.nix2container.buildImage (import ./ci/container-image {inherit pkgs yk8sDeps interactiveDeps;});
        formatter = pkgs.alejandra;
      };
    };
}
