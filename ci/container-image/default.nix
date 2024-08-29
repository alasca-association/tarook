{
  pkgs,
  dependencies,
}: let
  ciFiles = pkgs.stdenv.mkDerivation {
    name = "ci-files";
    src = ./.;
    postInstall = ''
      mkdir -p $out/root/.ssh
      cp known_hosts $out/root/.ssh/known_hosts
      cp gitconfig $out/root/.gitconfig
      cp openrc_f1a.sh $out/root/openrc.sh
    '';
  };
  tmpdir = pkgs.runCommand "tmp-dir" {} "mkdir -p $out/tmp;";
in {
  name = "registry.gitlab.com/yaook/k8s/ci";
  contents = pkgs.buildEnv {
    name = "image-root";
    paths =
      dependencies.yk8s
      ++ dependencies.ci
      ++ (with pkgs; [
        bashInteractive
        fakeNss # provides /etc/passwd and /etc/group
        dockerTools.usrBinEnv
        dockerTools.caCertificates
        ciFiles
        tmpdir
      ]);
  };
  fakeRootCommands = ''
    chmod 777 ${tmpdir}
  '';
  config = {
    Cmd = [
      "${pkgs.bashInteractive}/bin/bash"
    ];
    Env = [
      "wg_private_key_file=/root/wg.key"
      "wg_user=gitlab-ci-runner"
      "TF_VAR_keypair=gitlab-ci-runner"
      "HOME=/root"
    ];
  };
  maxLayers = 100;
}
