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
      flake = {lib, ...}: {
        flakeModules.yk8s = import ./nix/module;
        lib = rec {
          importTOML = file: fromTOML (builtins.readFile file);
          importYAML = pkgs: file: let
            jsonFile = pkgs.runCommandNoCC "converted-yaml.json" {} ''
              ${pkgs.yj}/bin/yj < "${file}" > "$out"
            '';
          in
            builtins.fromJSON (builtins.readFile jsonFile);
          importYamlTree = pkgs: dir: (lib.attrsets.mapAttrs' (file: _: {
            name = lib.strings.removeSuffix ".yaml" file;
            value = importYAML pkgs "${dir}/${file}";
          }) (builtins.readDir dir));
        };
        templates.cluster-repo = {
          description = ''
            Template containing all the Nix parts of the cluster repo
          '';
          path = ./nix/templates/cluster-repo;
        };
      };
    };
}
