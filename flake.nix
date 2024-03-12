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
        yk8sDependencies = with pkgs; [
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
        interactiveDependencies = with pkgs; [
          bashInteractive
          coreutils
        ];
        ciFiles = pkgs.stdenv.mkDerivation {
          name = "ci-files";
          src = ./ci/container-image;
          postInstall = ''
            mkdir -p $out/root/.ssh
            cp known_hosts $out/root/.ssh/known_hosts
            cp openrc_f1a.sh $out/root/openrc.sh
          '';
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
          nativeBuildInputs = interactiveDependencies;
          buildInputs = yk8sDependencies;
        };
        packages.ciImage =
          nix2containerPkgs.nix2container.buildImage
          {
            name = "localhost/yk8s-ci-image";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths =
                yk8sDependencies
                ++ interactiveDependencies
                ++ (with pkgs; [
                  dockerTools.usrBinEnv
                  dockerTools.caCertificates
                  ciFiles
                ]);
            };
            config = {
              Cmd = [
                "${pkgs.bashInteractive}/bin/bash"
              ];
              Env = [
                "wg_private_key_file=/root/wg.key"
                "wg_user=gitlab-ci-runner"
                "TF_VAR_keypair=gitlab-ci-runner"
              ];
            };
          };
        formatter = pkgs.alejandra;
      };
    };
}
