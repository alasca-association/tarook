{
  pkgs,
  inputs',
  ...
}: {
  yk8s-env = {
    dependencies.groups = with pkgs; {
      # Will be used by direnv when MINIMAL_ACCESS_VENV=true
      minimal.packages = [
        jq
        kubectl
        rsync
        inputs'.nixpkgs-vault1148.legacyPackages.vault
        yq
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
        iproute2 # for wg-up
        wireguard-tools
        util-linux # for uuidgen
      ];

      dev.includes = ["default"];
      dev.packages = [
        ansible-lint
        pre-commit
      ];

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
