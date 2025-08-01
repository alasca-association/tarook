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
          coreutils
          curl
          gnugrep
          gnused
          gzip
          kubernetes-helm
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
            # https://gitlab.com/yaook/k8s/-/merge_requests/1982#note_2669012669
            (kubernetes-validate.overrideAttrs {inherit (inputs'.nixpkgs-unstable.legacyPackages.python3Packages.kubernetes-validate) src version;})
            openshift
            loguru
            packaging
            python-openstackclient
            jsonschema
            hvac
            boto3
          ];
      };

      docs = {
        description = "Dependencies needed to built the documentation";
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
        description = "This is the recommended group for development work on YAOOK/K8s";
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
            GitPython
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
