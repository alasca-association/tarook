{dependencies}: {
  inputs,
  lib,
  self,
  flake-parts-lib,
  ...
}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        options,
        pkgs,
        inputs',
        system,
        ...
      }: let
        yk8s-lib = import ./lib {inherit lib pkgs;};
        removed-lib = import ./lib/removed.nix {inherit lib;};
        inherit (removed-lib) mkRemovedSectionModule;
        inherit (lib) types mkOption;
        inherit (yk8s-lib) mkInternalOption linkToPath;
        cfg = config.yk8s;
      in {
        config._module.args = {
          inherit yk8s-lib;
          # Pin all programs exported by this module to the version managed in the yaook/k8s repo
          pkgs = import inputs.yk8s.inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              builtins.elem (inputs.nixpkgs.outputs.lib.getName pkg) [
                "terraform"
                "vault"
              ];
          };
        };
        imports = [
          ./assertions.nix
          ./terraform.nix
          ./vault.nix
          ./load-balancing.nix
          ./kubernetes
          ./node-scheduling.nix
          ./testing.nix
          ./custom.nix
          ./nvidia.nix
          ./miscellaneous.nix
          ./k8s-supplements.nix
          (mkRemovedSectionModule "passwordstore" "Passwordstore has been replaced by Vault.")
        ];
        options.yk8s = {
          cluster_repository = mkOption {
            # TODO replace with state directory?
            description = ''
              The path to the cluster repository relative to the Nix file
              in which it is defined.
            '';
            type = types.pathInStore;
            example = "cluster repository = ./.; # from flake.nix";
          };
          _inventory_base_path = mkOption {
            description = ''
              Base path to the Ansible inventory. Files will get written here.
            '';
            type = types.str;
            default = "inventory/yaook-k8s";
          };
          _state_base_path = mkOption {
            description = ''
              Base path to the state directory. Files will get written here.
            '';
            type = types.str;
            default = "state";
          };
          _inventory_packages = mkInternalOption {
            description = ''
              Inventory packages from all sections that are then merged into the inventory directory
            '';
            type = with types; listOf package;
            default = [];
          };
          _state_packages = mkInternalOption {
            description = ''
              State packages from all sections that are then merged into the state directory
            '';
            type = with types; listOf package;
            default = [];
          };
        };
        config.packages = rec {
          yk8s-inventory = pkgs.buildEnv {
            name = "yaook-k8s-inventory";
            paths = cfg._inventory_packages;
          };
          yk8s-state-dir = pkgs.buildEnv {
            name = "yaook-k8s-state-dir";
            paths = cfg._state_packages;
          };
          yk8s-outputs = let
            inherit (builtins) map filter concatStringsSep trace;
            inherit (lib) showWarnings;
            failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.yk8s.assertions);
            baseSystemAssertWarn =
              if failedAssertions != []
              then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
              else showWarnings config.yk8s.warnings "";
          in
            builtins.seq baseSystemAssertWarn pkgs.buildEnv {
              name = "yaook-k8s-outputs";
              paths = [
                (linkToPath yk8s-inventory cfg._inventory_base_path)
                # (linkToPath yk8s-state-dir cfg._state_base_path)
                yk8s-state-dir
              ];
            };
          update-inventory = pkgs.writeShellApplication {
            name = "update-inventory";
            runtimeInputs = with pkgs; [rsync];
            text = ''
              if nix --version | grep "Lix" >/dev/null; then
                nix flake update yk8s
              else
                nix flake lock --update-input yk8s
              fi
              out=$(nix build --print-out-paths --no-link .#yk8s-outputs)
              rsync -rL --chmod 664 "$out/" .
            '';
          };
          action = pkgs.writeShellApplication {
            name = "yaook-k8s-action";
            runtimeInputs = (dependencies pkgs).yk8s;
            text = ''
              bash "${../..}/actions/$1"
            '';
          };
        };
      });
  };
}
