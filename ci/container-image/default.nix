{
  yk8sDeps,
  interactiveDeps,
  pkgs,
}: let
  ciFiles = pkgs.stdenv.mkDerivation {
    name = "ci-files";
    src = ./.;
    postInstall = ''
      mkdir -p $out/root/.ssh
      cp known_hosts $out/root/.ssh/known_hosts
      cp openrc_f1a.sh $out/root/openrc.sh
    '';
  };
in {
  # name = "localhost/yk8s-ci-image";
  name = "registry.gitlab.com/yaook/k8s/ci-image-nix-test";
  tag = "latest";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths =
      yk8sDeps
      ++ interactiveDeps
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
}
