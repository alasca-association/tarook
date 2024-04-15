{
  yk8sDeps,
  interactiveDeps,
  ciDeps,
  pkgs,
  nix2container,
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
in
  nix2container.buildImage {
    name = "registry.gitlab.com/yaook/k8s/ci";
    tag = "build";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = let
        filterDeps = with pkgs; e: ! builtins.any (i: i == e) [terraform vault ciFiles];
      in
        builtins.filter filterDeps (yk8sDeps
          ++ interactiveDeps
          ++ ciDeps
          ++ (with pkgs; [
            dockerTools.usrBinEnv
            dockerTools.caCertificates
            ciFiles
          ]));
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
    maxLayers = 100;
    layers = with pkgs;
      builtins.map (p: (nix2container.buildLayer {
        copyToRoot = p;
      })) [terraform vault ciFiles];
  }
