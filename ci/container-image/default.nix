{flake-parts-lib, ...}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        pkgs,
        lib,
        ...
      }: let
        ciFiles = pkgs.stdenv.mkDerivation {
          name = "ci-files";
          src = ./.;
          postInstall = ''
            mkdir -p $out/root/.ssh
            cp known_hosts $out/root/.ssh/known_hosts
            cp gitconfig $out/root/.gitconfig
          '';
        };
        userSetup = pkgs.stdenv.mkDerivation {
          name = "user-setup";
          src = ./.;
          postInstall = ''
            install -D -m622 user-setup/group $out/etc/group
            install -D -m622 user-setup/passwd $out/etc/passwd
            install -D -m620 user-setup/shadow $out/etc/shadow
          '';
        };
        nixConfig = pkgs.stdenv.mkDerivation {
          name = "nix-config";
          src = ./.;
          postInstall = ''
            install -D nix.conf $out/etc/nix/nix.conf
          '';
        };
        yk8sEnv = pkgs.stdenv.mkDerivation {
          # This is an empty derivation that pulls the runtime dependencies of YAOOK/K8s into the container
          # image without adding them to PATH. This way, our direnv is tested within the CI
          name = "yk8s-env";
          src = ./.;
          postInstall = ''
            mkdir $out
            # we need some file. otherwise, Nix will optimize away the empty derivation
            touch $out/.empty
          '';
          propagatedBuildInputs = with config.yk8s-env.environments; [default dev docs];
        };
        tmpdir = pkgs.runCommand "tmp-dir" {} "mkdir -p $out/tmp;";
        container-image = {
          name = "registry.gitlab.com/alasca.cloud/tarook/tarook/ci";
          contents = [
            yk8sEnv
            (pkgs.buildEnv {
              name = "image-root";
              paths = with pkgs; [
                config.yk8s-env.environments.ci
                bashInteractive
                dockerTools.usrBinEnv
                dockerTools.caCertificates
                ciFiles
                tmpdir
                userSetup
                nixConfig
              ];
            })
          ];
          includeNixDB = true;
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
          maxLayers = 120;
        };
      in {
        packages = {
          ciImage = pkgs.dockerTools.buildLayeredImage container-image;
          streamCiImage = pkgs.writeShellScriptBin "stream-ci" (pkgs.dockerTools.streamLayeredImage container-image);
        };
      });
  };
}
