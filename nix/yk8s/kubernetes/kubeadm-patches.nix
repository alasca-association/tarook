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
  };

  config.yk8s.kubernetes.kubeadm = {
    patches_dir = let
      patches = lib.mapAttrs (_: v: let
        maxLength = lib.stringLength (toString (lib.length v));
      in
        lib.pipe v [
          (lib.sort (a: b: a.priority < b.priority)) # Sort patches by priority
          (lib.imap0 (i: v: v // {suffix = lib.fixedWidthNumber maxLength i;})) # Create suffix from priority with unique values starting from 0
        ])
      cfg.kubeadm.patches;
    in
      (pkgs.buildEnv {
        name = "kubeadm-patches";
        paths = lib.flatten (
          lib.mapAttrsToList (
            target: map (p: yk8s-lib.mkJsonAtPath "${target}${p.suffix}+${p.patchtype}.json" p.patch)
          )
          patches
        );
      }).outPath;
  };
}
