{
  yk8sDeps,
  interactiveDeps,
  ciDeps,
  pkgs,
  nix2container,
}: rec {
  base = nix2container.buildImage {
    name = "registry.gitlab.com/yaook/k8s/ci-image-nix-base";
    tag = "build";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths =
        yk8sDeps
        ++ interactiveDeps
        ++ ciDeps
        ++ (with pkgs; [
          dockerTools.usrBinEnv
          dockerTools.caCertificates
        ]);
    };
    config = {
      Cmd = [
        "${pkgs.bashInteractive}/bin/bash"
      ];
    };
    maxLayers = 100;
  };
  f1a = let
    ciFiles = pkgs.stdenv.mkDerivation {
      name = "ci-files";
      src = ./.;
      postInstall = ''
        mkdir -p $out/root/.ssh
        cp known_hosts $out/root/.ssh/known_hosts
        cp openrc_f1a.sh $out/root/openrc.sh
      '';
    };
  in
    nix2container.buildImage {
      name = "registry.gitlab.com/yaook/k8s/ci-image-nix-f1a";
      fromImage = base;
      config = {
        copyToRoot = ciFiles;
        Env = [
          "wg_private_key_file=/root/wg.key"
          "wg_user=gitlab-ci-runner"
          "TF_VAR_keypair=gitlab-ci-runner"
        ];
      };
    };
}
