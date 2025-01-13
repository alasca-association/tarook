{
  pkgs,
  inputs',
  ...
}: {
  yk8s-env = {
    python = pkgs.python311;
    dependencies.groups = with pkgs; {
      # Will be used by direnv when MINIMAL_ACCESS_VENV=true
      minimal.packages = [
        iproute2 # for wg-up
        jq
        kubectl
        rsync
        inputs'.nixpkgs-vault1148.legacyPackages.vault
        wireguard-tools
        yq
      ];
      minimal.pythonPackages = ps:
        with ps; [
          ansible-core
        ];

      # Will be used by direnv by default
      default.includes = ["minimal"];
      default.packages = [
        coreutils
        gnugrep
        gnused
        gzip
        kubernetes-helm
        moreutils
        openssh
        openssl
        inputs'.nixpkgs-terraform157.legacyPackages.terraform
        util-linux # for uuidgen
      ];
      default.pythonPackages = ps:
        assert !ps ? "kubernetes-validate"; # This will fail as soon as kubernetes-validate is inside nixpkgs; reminding us to remove our own copy of the package
        
        with ps; [
          kubernetes
          (callPackage ./pkgs/kubernetes-validate.nix {})
          openshift
          openstackclient-full
          loguru
          packaging
          jsonschema
          hvac
          boto3
        ];

      docs.pythonPackages = ps:
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

      dev.includes = ["default" "docs"];
      dev.packages = [
        (ansible-lint.overrideAttrs (
          {propagatedBuildInputs ? [], ...}: {
            propagatedBuildInputs =
              propagatedBuildInputs ++ [pkgs.python3.pkgs.jmespath];
          }
        ))
        pre-commit
      ];
      dev.pythonPackages = ps:
        with ps; [
          flake8
        ];

      ci.includes = ["default" "dev" "docs"];
      ci.packages = [
        direnv
        git
        gnupg
        gnutar
        netcat
        nix
        sonobuoy
      ];
      ci.pythonPackages = ps:
        with ps; [
          GitPython
        ];

      interactive.includes = ["default" "dev"];
      interactive.packages = [
        bashInteractive
        curl
        vim
        dnsutils
        iputils
        k9s
      ];
    };
  };
}
