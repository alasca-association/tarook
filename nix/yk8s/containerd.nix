{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.containerd;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types mkDisableOption;
in {
  options.yk8s.containerd = mkTopSection {
    _docs.preface = ''
      By default changes to the following options are only applied to newly provisioned Kubernetes nodes,
      because restarting containerd is considered unsafe for already initialized Kubernetes nodes.

      To apply configuration changes on **all** Kubernetes nodes, do one of the following:

      a. Run a :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>` with :ref:`actions-references.upgradesh`
      b. Run a host OS update against all nodes with :ref:`actions-references.update-kubernetes-nodessh`
      c. Run :ref:`actions-references.apply-k8s-coresh` with disruption allowed (not recommended)

         .. warning::

            This is potentially disruptive,
            because it does not drain nodes before restarting components like containerd.

            .. code:: console

               $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-k8s-core.sh prepare-k8s-nodes.yaml

    '';
    version = mkOption {
      description = ''
        The containerd version to be deployed on Kubernetes nodes.

        .. note::

          Changes to this option potentially downgrades containerd.
      '';
      type = types.yk8s.version.semver2VersionStr;
      # renovate: datasource=github-releases packageName=containerd/containerd
      default = "2.4.2";
      example = "2.2.1";
    };
    discard_unpacked_layers = mkDisableOption ''
      discarding of unpacked layers.
      This allows containerd's garbage collection
      to remove layers from the content store after
      successfully unpacking these layers to the snapshotter.

      .. note::

         Already existing layers in the content store will not be removed.
         We recommend to run ``ctr -n k8s.io content prune references``
         on each Kubernetes node when enabling this option.

      See `full configuration of containerd <https://containerd.io/docs/2.4/cri/config/#full-configuration>`__
    '';
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
  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "containerd_";
      inventory_path = "all/containerd.yaml";
    })
  ];
}
