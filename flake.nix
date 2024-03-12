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
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
        inputs',
        ...
      }: let
        dependencies = with pkgs; {
          yk8s = [
            jq
            kubectl
            kubernetes-helm
            moreutils
            openssl
            openstackclient
            poetry
            terraform
            vault
            wireguard-tools
          ];
          ci = with pkgs; [
            git
          ];
          interactive = with pkgs; [
            bashInteractive
            dnsutils
            iputils
            k9s
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
        };
        formatter = pkgs.alejandra;
      };
    };
}
