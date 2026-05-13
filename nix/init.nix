{
  lib,
  pkgs,
  config,
  ...
}: let
  templateDir = ./templates/cluster-repo;
  targets = lib.pipe templateDir [
    lib.readDir
    (lib.filterAttrs (name: type: type == "directory" && name != "_common"))
    lib.attrNames
  ];
  targetList = lib.concatStringsSep ", " targets;
  targetCases = lib.concatStringsSep "|" targets;
in {
  apps = {
    template = {
      type = "app";
      meta.description = ''
        Initialize the current directory with a template.
      '';
      program = pkgs.writeShellApplication {
        name = "template";
        runtimeInputs = [pkgs.rsync];
        text = ''
          if [ "$#" -lt 1 ]; then
            echo "Usage: nix run <flake>.#template <target>"
            echo
            echo "Currently supported targets: ${targetList}"

            exit 1
          fi

          target="$1"
          case "$target" in
            ${targetCases})
              ;;
            *)
              echo "Unsupported target."
              echo "Currently supported targets: ${targetList}"
              exit 1
              ;;
          esac

          src="${templateDir}"
          rsync --verbose --chmod=644 --recursive --ignore-existing "$src/_common"/ "$src/$target"/ .
        '';
      };
    };

    init = {
      type = "app";
      meta.description = "Initialize a cluster repository via 'nix run'";
      program = pkgs.writeShellApplication {
        name = "init-cluster-repo";
        runtimeInputs = [config.yk8s-env.environments.default];
        text = ''
          while getopts ":b:" flag
          do
            case "$flag" in
              b)
                export MANAGED_K8S_LATEST_RELEASE=false
                export MANAGED_K8S_GIT_BRANCH="$OPTARG"
                ;;
              :)
                echo "Option -$OPTARG requires an argument" >&2
                exit 1
                ;;
              \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            esac
          done

          shift $(( OPTIND - 1 ))
          [[ "''${1:-}" == "--" ]] && shift

          case "$1" in
            ${targetCases})
              target="$1"
            ;;
            *)
              echo "Unsupported target."
              echo "Currently supported targets: ${targetList}"
              echo "Falling back to using $OPTARG as branch name for backwards compatibility."
              echo "THIS IS DEPRECATED AND WILL BE REMOVED IN A FUTURE RELEASE."
              echo "Use -b instead!"

              target=openstack
              export MANAGED_K8S_LATEST_RELEASE=false
              export MANAGED_K8S_GIT_BRANCH="$OPTARG"
            ;;
          esac

          ${./..}/actions/init-cluster-repo.sh "$target"
        '';
      };
    };
  };
}
