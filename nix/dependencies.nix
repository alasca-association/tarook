{
  pkgs,
  inputs',
  ...
}: {
  yk8s-env = {
    dependencies.groups = with pkgs; {
      minimal.description = "Will be used by direnv when MINIMAL_ACCESS_VENV=true";
      minimal.packages = [
        jq
        kubectl
        rsync
        inputs'.nixpkgs-vault1148.legacyPackages.vault
        yq
      ];

      default.description = "Will be used by direnv by default";
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
        iproute2 # for wg-up
        wireguard-tools
        util-linux # for uuidgen
      ];

      dev.description = "This is the recommended group for development work on YAOOK/K8s";
      dev.includes = ["default"];
      dev.packages = [
        ansible-lint
        pre-commit
      ];

      ci.description = "Dependencies directly needed by the CI jobs.";
      ci.includes = ["default" "dev"];
      ci.packages = [
        direnv
        git
        gnupg
        gnutar
        netcat
        nix
        sonobuoy
      ];

      interactive.description = "This group contains additional packages that may be useful in an interactive session";
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
