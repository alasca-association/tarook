{
  pkgs,
  inputs',
  ...
}: {
  yk8s-env = {
    python = pkgs.python3;
    dependencies.groups = with pkgs; {
      update-inventory = {
        description = "Dependencies needed by update-inventory.sh";
        packages = [
          git
          rsync
        ];
      };
      minimal = {
        description = "Will be used by direnv when MINIMAL_ACCESS_VENV=true";
        includes = ["update-inventory"];
        packages = [
          iproute2 # for wg-up
          jq
          kubectl
          inputs'.nixpkgs-vault1148.legacyPackages.vault
          wireguard-tools
          yq
        ];
        pythonPackages = ps:
          with ps; [
            ansible-core
          ];
      };

      default = {
        description = "Will be used by direnv by default";
        includes = ["minimal"];
        packages = [
          (wrapHelm kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-diff
            ];
          })
          coreutils
          curl
          gnugrep
          gnused
          gzip
          moreutils
          openssh
          openssl
          pre-commit
          inputs'.nixpkgs-terraform157.legacyPackages.terraform
          util-linux # for uuidgen
        ];
        pythonPackages = ps:
          with ps; [
            kubernetes
            kubernetes-validate
            openshift
            loguru
            packaging
            python-openstackclient
            jsonschema
            hvac
          ];
      };

      docs = {
        description = "Dependencies needed to built the documentation";
        packages = with pkgs; [
          git # for towncrier
        ];
        pythonPackages = ps:
          with ps; [
            sphinx
            sphinx-rtd-theme
            sphinx-tabs
            furo
            towncrier
            sphinx-multiversion
            myst-parser
            sphinx-design
            sphinx-copybutton
            sphinx-jinja
          ];
      };

      lint = {
        description = "Dependencies needed by the linting stage and for the pre-commit hook";
        packages = [
          (ansible-lint.overrideAttrs (
            {propagatedBuildInputs ? [], ...}: {
              propagatedBuildInputs =
                propagatedBuildInputs ++ [pkgs.python3.pkgs.jmespath];
            }
          ))
          pre-commit
        ];
        pythonPackages = ps:
          with ps; [
            ansible-core
            flake8
          ];
      };

      dev = {
        description = "This is the recommended group for development work on Tarook";
        includes = ["default" "docs" "lint"];
      };

      ci = {
        description = ''
          Dependencies directly needed by the CI jobs.
          Note that this does not include "default" because the runtime dependencies are
          enabled through direnv during the run.
        '';
        includes = ["docs" "lint"];
        packages = [
          coreutils
          gnugrep
          direnv
          git
          gnupg
          gnutar
          netcat
          nix
          rsync
          sonobuoy
        ];
        pythonPackages = ps:
          with ps; [
            gitpython
            python-openstackclient
          ];
      };

      interactive = {
        description = "This group contains additional packages that may be useful in an interactive session";
        includes = ["default" "dev"];
        packages = [
          bashInteractive
          vim
          dnsutils
          iputils
          k9s
        ];
      };
    };
  };
}
