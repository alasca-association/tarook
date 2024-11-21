{
  pkgs,
  inputs',
  ...
}: {
  yk8s-env = {
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

      # Will be used by direnv by default
      default.depends = ["minimal"];
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

      dev.depends = ["default" "docs"];
      dev.packages = [
        ansible-lint
        pre-commit
      ];

      ci.depends = ["default" "dev" "docs"];
      ci.packages = [
        direnv
        git
        gnupg
        gnutar
        netcat
        nix
        sonobuoy
      ];

      interactive.depends = ["default" "dev"];
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
