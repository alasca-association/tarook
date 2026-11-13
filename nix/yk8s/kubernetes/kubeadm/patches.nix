{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkInternalOption types;
in {
  options.yk8s.kubernetes.kubeadm = {
    patches = let
      patchesSubmodule = types.submodule {
        options = {
          priority = mkOption {
            description = ''
              Higher priority means the patch will be applied later.

              The order in which patches with the same priority are applied is undefined.
            '';
            type = types.int;
            default = 0;
          };
          identifier = mkOption {
            description = ''
              An optional string that will be part of the patch's filename in order to
              quickly identify it.
            '';
            type = types.strMatching "[a-z0-9-]*";
            default = "";
          };
          patchtype = mkOption {
            description = ''
              The type of the patch.

              For an explanation on each of them, see
              `Update API Objects in Place Using kubectl patch <https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch>`_
            '';
            type = types.enum [
              "strategic"
              "merge"
              "json"
            ];
            default = "strategic";
          };
          patch = mkOption {
            description = ''
              The patch to be applied.

              You may use ``patch = yk8s-lib.importYAML ./path/to/patch.yaml;`` to import
              an existing manifest.

              .. note::

                 The YAML file has to be added to the git repository
                 in order to be evaluated by Nix.

              Alternatively, if you prefer to specify the patch in Nix directly, you may use
              `json2nix <https://github.com/cloudandheat/json2nix>`_
              to convert your existing patches to Nix.
            '';
            type = types.yk8s.formats.jsonValue;
            example = [
              {
                op = "remove";
                path = "/spec/containers/0/resources";
              }
            ];
          };
        };
      };
    in
      lib.listToAttrs (
        lib.forEach [
          "kube-apiserver"
          "kube-controller-manager"
          "kube-scheduler"
          "etcd"
          "kubeletconfiguration"
          "corednsdeployment"
        ] (
          target: {
            name = target;
            value = mkOption {
              description = ''
                Patches for ${target}.

                Check out the Kubernetes Documentation
                `kubeadm: Customizing with patches <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#patches>`_
                for further information on how to configure.
              '';
              type = with types; listOf patchesSubmodule;
              example = [
                {
                  patchtype = "json";
                  patch = [
                    {
                      op = "add";
                      path = "/spec/containers/0/command/-";
                      value = "--profiling=false";
                    }
                  ];
                }
              ];
              default = [];
            };
          }
        )
      );

    patches_dir = mkInternalOption {
      type = types.pathInStore;
      readOnly = true;
    };
    patchFiles = mkInternalOption {
      description = ''
        The kubeadm patch files of each node by file name.
      '';
      type = with types; attrsOf (attrsOf yk8s.formats.jsonValue);
      readOnly = true;
    };
    patches_remote_dir = mkInternalOption {
      readOnly = true;
      type = types.yk8s.posix.absolutePath;
      default = "/etc/kubernetes/kubeadm-patches";
    };
  };

  config.yk8s.kubernetes.kubeadm = {
    patchFiles = let
      sortedPatches = lib.mapAttrs (_: lib.sort (a: b: a.priority < b.priority)) cfg.kubeadm.patches;
      # kubeadm applies the patches of a target in the order of their file names
      toFiles = lib.concatMapAttrs (target: v: let
        # Pad the numbers to the same width, otherwise e.g. "10" sorts before "2"
        width = lib.stringLength (toString (lib.length v));
      in
        lib.listToAttrs (lib.imap0 (i: p: lib.nameValuePair "${target}${lib.fixedWidthNumber width i}${p.identifier}+${p.patchtype}.json" p.patch) v));
    in
      lib.mapAttrs (
        _: hostValues:
          toFiles (
            # Worker nodes only need the patches for the kubelet
            if hostValues.role == "master"
            then sortedPatches
            else {inherit (sortedPatches) kubeletconfiguration;}
          )
      )
      config.yk8s.infra.final_hosts.k8s_nodes.hosts;

    # One directory per node
    patches_dir =
      (pkgs.linkFarm "kubeadm-patches" (
        lib.concatLists (lib.mapAttrsToList (
            node:
              lib.mapAttrsToList (name: patch: {
                name = "${node}/${name}";
                path = yk8s-lib.mkJson name patch;
              })
          )
          cfg.kubeadm.patchFiles)
      )).outPath;
  };
}
