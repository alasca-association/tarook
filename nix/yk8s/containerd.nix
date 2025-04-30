{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.containerd;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
in {
  options.yk8s.containerd = mkTopSection {
    version = mkOption {
      description = ''
        The containerd version to be deployed on Kubernetes nodes.

        Changes to this option only directly affect newly provisioned Kubernetes nodes.
        To adjust the containerd version on **all** Kubernetes nodes,
        either do a :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`,
        update the OS packages on all nodes via
        :ref:`update-kubernetes-nodes.sh<actions-references.update-kubernetes-nodessh>`,
        or, if you are brave, run:

        .. warning::

           This is potentially disruptive.

        .. code:: console

           $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-k8s-core.sh prepare-k8s-nodes.yaml

        .. note::

          Changes to this option potentially downgrades containerd.
      '';
      type = types.yk8s.version.semver2VersionStr;
      # renovate: datasource=github-releases packageName=containerd/containerd
      default = "2.1.5";
      example = "2.2.1";
    };
    mirrors = mkOption {
      description = ''
        Registry mirrors which will be configured for containerd.
        These can act as pull through cache to reduce external network traffic
        and the amount of pulls from registries which have rate limits.
        The upstream registry will automatically be used after all defined hosts have been tried.
      '';
      type = types.listOf (types.submodule {
        options = {
          registry = mkOption {
            type = with types; nullOr yk8s.networking.subdomainName;
            description = ''
              Name of the registry host for which the mirrors should be used.
              Registry hosts are typically referred to by their internet domain names, aka. registry host names.
              For example, docker.io, quay.io, gcr.io, and ghcr.io.
              Set to null if the mirrors should be used as default.
            '';
            example = "gcr.io";
          };
          mirrors = mkOption {
            type = with types; listOf yk8s.networking.httpsHostPathUrl;
            example = ["https://registry-1.example.com" "https://registry-2.example.com:5000"];
            description = ''
              A list of URLs which should be substituted for the registry.
              Optionally specify a port.
            '';
          };
        };
      });
      default = [];
      example = [
        {
          registry = "docker.io";
          mirrors = ["https://registry-cache-1.example.com" "https://registry-cache-2.example.com:5000"];
        }
        {
          registry = "some.container.registry";
          mirrors = ["https://registry-cache-3.example.com"];
        }
        {
          registry = null;
          mirrors = ["https://registry-cache-4.example.com"];
        }
      ];
    };
  };
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "containerd_";
      inventory_path = "all/containerd.yaml";
    })
  ];
}
