{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.openbao;
  opts = options.yk8s.k8s-service-layer.openbao;

  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkGroupVarsFile mkTopSection;
  inherit (yk8s-lib.options) mkHelmReleaseOptions mkInternalOption;
  inherit (yk8s-lib.transform) removeAttrsByPath updateManyAttrsByPathIf;
in {
  options.yk8s.k8s-service-layer.openbao = mkTopSection {
    enabled = mkEnableOption "deployment of OpenBao on Kubernetes";
    helm = mkHelmReleaseOptions {
      descriptionName = "OpenBao";
      defaultRepoUrl = "https://openbao.github.io/openbao-helm";
      defaultChartRef = "openbao";
      # renovate: datasource=helm depName=openbao registryUrl=https://openbao.github.io/openbao-helm
      defaultChartVersion = "0.6.0";
      defaultReleaseNamespace = "k8s-svc-openbao";
      defaultReleaseName = "openbao";
      valuesDocUrl = "https://github.com/openbao/openbao-helm/blob/openbao-0.6.0/charts/openbao/values.yaml";
      extraValuesDescription = ''
        TODO
      '';
    };
    backups = mkOption {
      description = ''
        TODO
      '';
      type = types.attrsOf (types.submodule {
        options = {
          enabled = mkEnableOption "periodic backups";
          # TODO: Check if we need more options here
        };
      });
      default = {};
    };

    # Finalize cfg.helm.values
    # NOTE: Users may configure different charts that may have different values,
    #       in which case these final updates do not apply.
    #       As a simple heuristic we assume that charts with the same chart ref
    #       have the same set of chart values,
    #       therefore apply the updates only if the chart ref is unchanged
    helm_finalValues = mkInternalOption {
      type = opts.helm.values.type;
      default =
        if (cfg.helm.chart_ref != opts.helm.chart_ref.default)
        then cfg.helm.values
        else let
          # Collects `tls_cert_file`, `tls_key_file` and `tls_ca_file`
          # from the given list of OpenBao listeners
          # iff those file paths have been specified as a list
          collectSegmentedMountPathsFromListeners = listeners:
            lib.pipe listeners [
              # extract listener attrs
              (lib.map (listener: lib.attrValues listener))
              lib.flatten
              # collect tls attrs if present and of type 'list'
              (lib.foldl (
                acc: listenerAttrs:
                  acc
                  ++ lib.foldl (
                    acc_: tlsAttrName: let
                      tlsAttr = lib.attrByPath [tlsAttrName] null listenerAttrs;
                    in
                      acc_ ++ lib.optional (lib.isList tlsAttr) tlsAttr
                  )
                  [] ["tls_cert_file" "tls_key_file" "tls_ca_file"]
              ) [])
              # drop duplicates
              lib.unique
            ];
          segmentedMountPaths =
            collectSegmentedMountPathsFromListeners
            (cfg.helm.values.server.ha.raft.config.listener or []);

          # Returns the first listener from the list of OpenBao listeners
          # or an empty attrset
          firstOpenbaoListener = helmValues:
            lib.pipe (helmValues.server.ha.raft.config.listener or []) [
              (x: lib.optionalAttrs (lib.length x != 0) (lib.elemAt x 0))
              lib.attrValues
              (x: lib.optionalAttrs (lib.length x != 0) (lib.elemAt x 0))
            ];
      in
          updateManyAttrsByPathIf ([
            # Finalize cfg.helm.values.server.ha.raft.config.listener spec:
            # - Drop `tls_ca_file`
            # - Turn `tls_cert_file` and `tls_key_file` into strings if they are lists
            {
              path = ["server" "ha" "raft" "config" "listener"];
              updateIf = update: helmValues: lib.hasAttrByPath update.path helmValues;
              update =
                lib.map (
                  listener:
                    lib.mapAttrs (
                      _: listenerAttrs:
                        lib.pipe listenerAttrs [
                          (la: removeAttrsByPath la [["tls_ca_file"]])
                          (la: lib.updateManyAttrsByPath (
                            lib.foldl (
                              acc: tlsAttrName:
                                acc ++ (
                                  lib.optional
                                  (lib.hasAttr tlsAttrName la)
                                  {
                                    path = [tlsAttrName];
                                    update = old:
                                      if lib.isList old
                                      then lib.concatStringsSep "/" old
                                      else old;
                                  }
                                )
                            )
                            [] ["tls_cert_file" "tls_key_file"]
                          ) la)
                        ]
                    )
                    listener
                );
            }

            # Add a sidecar container for each Kubernetes secret
            # that we known of from the the OpenBao listener mount paths
            # so that OpenBao is reloaded whenever one of those secrets changes
            {
              path = ["server" "extraContainers"];
              updateIf = _: _: (lib.length segmentedMountPaths) != 0;
              update = old:
                lib.unique (
                  # tolerate `old` to not exist yet
                  (if (builtins.tryEval old).success then old else [])
                  ++ lib.pipe segmentedMountPaths [
                    # select secret names from segmented mount paths
                    (lib.map (path: lib.elemAt path 1))
                    lib.unique
                    (lib.map (
                      secret: {
                        name = "service-reload-${secret}";
                        # REVIEW:
                        # This looks like something we should version-pin and manage with renovate bot
                        image = "registry.yaook.cloud/yaook/service-reload:devel";
                        volumeMounts = [
                          {
                            name = secret;
                            mountPath = "/data";
                          }
                        ];
                        env = [
                          {
                            name = "YAOOK_SERVICE_RELOAD_MODULE";
                            value = "vault";
                          }
                          {
                            name = "TINI_SUBREAPER";
                            value = "1";
                          }
                        ];
                      }
                    ))
                  ]
                );
            }

            # Finalize server.shareProcessNamespace:
            # If set and set to `null`
            # update to a boolean based on whether there are extraContainers or not
            {
              path = ["server" "shareProcessNamespace"];
              updateIf = update: helmValues:
                (lib.hasAttrByPath update.path helmValues)
                && (lib.getAttrFromPath update.path helmValues == null);
              update = _:
                if (
                  ((lib.length (cfg.helm.values.server.extraContainers or [])) == 0)
                  # NOTE: since we extend extraContainers above
                  #       we need to count those as well
                  && ((lib.length segmentedMountPaths) == 0)
                )
                then false
                else true;
            }

            # Set the VAULT_PATH environment variable
            # to the TLS CA file for the internal OpenBao listener (first one)
            {
              path = ["server" "extraEnvironmentVars"];
              updateIf = update: helmValues:
                # only set if _not_ set already
                ! (lib.hasAttrByPath (update.path ++ ["VAULT_CAPATH"]) helmValues)
                && (lib.hasAttr "tls_ca_file" (firstOpenbaoListener helmValues));
              update = old:
                # tolerate `old` to not exist yet
                (if (builtins.tryEval old).success then old else {})
                // {
                  "VAULT_CAPATH" = with (firstOpenbaoListener cfg.helm.values);
                    # turn file path into a string if it was specified as a list
                    if lib.isList tls_ca_file
                    then lib.concatStringsSep "/" tls_ca_file
                    else tls_ca_file;
                };
            }

            # Add a Pod Volume for each Kubernetes secret
            # that we known of from the the OpenBao listener mount paths
            {
              path = ["server" "volumes"];
              updateIf = _: _: (lib.length segmentedMountPaths) != 0;
              update = old:
                # tolerate `old` to not exist yet
                (if (builtins.tryEval old).success then old else [])
                ++ lib.pipe segmentedMountPaths [
                  # select secret names from mount paths
                  (lib.map (path: lib.elemAt path 1))
                  lib.unique
                  # convert into Volume spec
                  (lib.map (
                    name: {
                      inherit name;
                      secret = {
                        secretName = name;
                      };
                    }
                  ))
                ];
            }

            # Add a volumeMount for each Kubernetes secret
            # that we known of from the the OpenBao listener mount paths
            # in order to mount the volumes added right above
            {
              path = ["server" "volumeMounts"];
              updateIf = _: _: (lib.length segmentedMountPaths) != 0;
              update = old:
                # tolerate `old` to not exist yet
                (if (builtins.tryEval old).success then old else [])
                ++ lib.pipe segmentedMountPaths [
                  # convert into VolumeMount spec
                  (lib.map (
                    path: {
                      name = lib.elemAt path 1;
                      mountPath = lib.elemAt path 0;
                      readOnly = true;
                    }
                  ))
                  lib.unique
                ];
            }
          ]
          # Update values in cfg.helm.values.server.ha.raft.config.storage."raft" if it exists
          ++ lib.optionals
          (lib.hasAttrByPath ["server" "ha" "raft" "config" "storage" "raft"] cfg.helm.values)
          [
            # Set leader API address if not set already
            {
              path = ["server" "ha" "raft" "config" "storage" "raft" "retry_join" "leader_api_addr"];
              updateIf = update: helmValues:
                ! (lib.hasAttrByPath update.path helmValues);
              update = _:
                 # TODO: Shouldn't we address the openbao-active service here?
                 #       Address taken from k8s-supplements/ansible/roles/vault_v1/templates/vault.yaml.j2
                "https://openbao.${cfg.helm.release_namespace}.svc.cluster.local:${toString cfg.helm.values.server.service.targetPort}";
            }

            # Set leader CA cert if not set already
            {
              path = ["server" "ha" "raft" "config" "storage" "raft" "retry_join" "leader_ca_cert_file"];
              updateIf = update: helmValues:
                ! (lib.hasAttrByPath update.path helmValues)
                && (lib.hasAttr "tls_ca_file" (firstOpenbaoListener helmValues));
              update = _:
                with (firstOpenbaoListener cfg.helm.values);
                # turn file path into a string if it was specified as a list
                if lib.isList tls_ca_file
                then lib.concatStringsSep "/" tls_ca_file
                else tls_ca_file;
            }
          ])
          cfg.helm.values;
    };
  };

  # Preset values for the default OpenBao Helm chart
  # NOTE: Users may configure different charts that may have different values,
  #       in which case these preset values do not apply or have different meanings.
  #       As a simple heuristic we assume that charts with the same chart ref
  #       have the same set of chart values,
  #       therefore apply the presets only if the chart ref is unchanged
  #       (see further below).
  # REVIEW:
  # lib.mkForce is used when Tarook's assume the value won't be changed
  # bare value is used for values fundamental to Tarook and ones that are dynamically set
  # lib.mkDefault is used for recommended values
  config.yk8s.k8s-service-layer.openbao.helm.values =
    lib.optionalAttrs
    (cfg.helm.chart_ref == opts.helm.chart_ref.default)
    {
      global = {
        enabled = true;

        # Deploy OpenBao in the `helm` installation namespace,
        # Tarook is going to assume this is always the case
        namespace = lib.mkForce "";

        tlsDisable = false;
      }
      # Enable Prometheus integration
      # if monitoring is enabled and Prometheus is installed
      # TODO: Test if we can use this instead of our own setup
      // lib.optionalAttrs (
        config.yk8s.kubernetes.monitoring.enabled
        && config.yk8s.k8s-service-layer.prometheus.install
      )
      {
        serverTelemetry.prometheusOperator = lib.mkForce true;
      };

      injector.enabled = false;

      server = {
        enabled = "-";

        # OpenBao's upgrade procedure requires the OnDelete strategy
        # see https://openbao.org/docs/2.3.x/platform/k8s/helm/run/#upgrading-openbao-on-kubernetes
        updateStrategyType = lib.mkForce "OnDelete";

        logLevel = lib.mkDefault "trace";

        # Disable ingress here since it is setup by Tarook itself
        # TODO: check whether we want to enable this
        #TODO            # We would like to use a different certificate (letsencrypt) which is valid in public in addition to the
        #TODO            # one which is derived from our custom CA. openbao should terminate TLS, not the ingress controller. To cope
        #TODO            # with the situation we add an additional API endpoint (8250) solely for this purpose. Unfortunately we cannot
        #TODO            # use the Ingress of the helm chart as its tied to the primary API endpoint (8200).
        ingress.enabled = lib.mkForce false;

        authDelegator.enabled = lib.mkDefault false;

        # NOTE: Default generated in cfg.helm_finalValues
        #extraContainers =

        # Share process namespace between OpenBao and the extraContainers.
        # If this option is `null` it will be set
        # to `true` when there are extraContainers and to `false` otherwise
        #
        # NOTE: This is needed because the extraContainers we add by default
        #       use the yaook/service-reload OCI image
        #       which rely on `pidof vault`.
        # NOTE: Finalized in cfg.helm_finalValues
        #
        # TODO:TODO: Check if we need to update service-reload with `pidof bao`
        shareProcessNamespace = lib.mkDefault null;

        # NOTE: Default generated in cfg.helm_finalValues
        #extraEnvironmentVars =

        # NOTE: Default generated in cfg.helm_finalValues
        #volumes =

        # NOTE: Default generated in cfg.helm_finalValues
        #volumeMounts =

        # The chart sets up inter-pod anti-affinity by default, dynamically,
        # therefore we don't configure it here
        #affinity = {}

        tolerations =
          []
          # Tolerate Kubernetes control plane taint in clusters without workers
          ++ lib.optional
          (lib.length (lib.attrValues config.yk8s.infra.final_hosts.workers.hosts) == 0)
          (yk8s-lib.k8s.mkTolerations "node-role.kubernetes.io/control-plane");

        # Mark OpenBao as system critical
        # because it may be used as secrets backend for other instances of Tarook
        # there being an essential component
        priorityClassName = "system-cluster-critical";

        # REVIEW:
        # Is this useful?
        # extraLabels = {
        #   "tarook.cloud/openbao" = "";
        # };

        service = {
          enabled = true;

          # Create a Kubernetes Service
          # that selects Pods labeled with `openbao-active=true`
          active.enabled = lib.mkForce true;

          # Create a Kubernetes Service
          # that selects Pods labeled with `openbao-active=false`
          standby.enabled = true;

          # Let Kubernetes Services select only Pods deployed from the Helm chart
          instanceSelector.enabled = true;

          type = lib.mkDefault "ClusterIP";

          ipFamilyPolicy =
            if (config.yk8s.infra.ipv4_enabled && config.yk8s.infra.ipv6_enabled)
            then lib.mkDefault "PreferDualStack"
            else "SingleStack";

          # NOTE: Set to so that it can be used for cfg.helm.values.server.ha.raft.config
          port = lib.mkDefault 8200;

          # NOTE: Set to so that it can be used for cfg.helm.values.server.ha.raft.config
          targetPort = lib.mkDefault 8200;
        };

        # Use persistent storage for OpenBao's data
        dataStorage = {
          enabled = true;

          size = lib.mkDefault "10Gi";

          # REVIEW:
          # Should we make this explicit?
          #
          # In Openstack environments use the 'csi-sc-cinderplugin' StorageClass
          # storageClass = lib.mkDefault (
          #   if config.yk8s.openstack.enabled
          #   # TODO: Set to the actual name of the deployed StorageClass
          #   then "csi-sc-cinderplugin"
          #   else null
          # );
        };

        # Disable audit storage since audit logging is not configured by default
        auditStorage.enabled = lib.mkDefault false;

        # Never deploy OpenBao in development mode
        dev.enabled = lib.mkForce false;

        # Deploy OpenBao in "HA" mode with 3 replicas
        standalone.enabled = false;
        ha = {
          enabled = true;

          replicas = 3;

          # Enable OpenBao's integrated Raft storage
          raft = {
            enabled = lib.mkDefault true;

            # TODO: check whether the helm chart expects a json string here
            config =
              {
                ui = lib.mkDefault true;

                # NOTE: Finalized in cfg.helm_finalValues
                #
                #       In order to generate a few other Helm values,
                #       based on the OpenBao listener stanzas below,
                #       we support the following deviations from the spec
                #       (see https://openbao.org/docs/configuration/listener/):
                #
                #       - The TLS file paths can be provided as a list of
                #         base path, name of the mounted secret and file path.
                #         If they are server.volumes, server.volumeMounts and
                #         server.extraContainers are generated accordingly.
                #       - The `tls_ca_file` attribute can be added to listeners
                #         but the first listener must be the internal one.
                #         If set server.ha.raft.config.storage.raft.retry_join.leader_ca_cert_file
                #         is set accordingly.
                # NOTE: Deprioritise to prevent list merges, users shall overwrite by default
                listener = lib.mkOverride 999 (let
                  inherit (cfg.helm.values.server.service) port;
                in [
                  {
                    "tcp" =
                      {
                        address = "[::]:${toString port}";
                        cluster_address = "[::]:${toString (port + 1)}";
                      }
                      // lib.optionalAttrs (! cfg.helm.values.global.tlsDisable) {
                        # TODO: Create those secrets in Ansible
                        tls_cert_file = ["/openbao/pki" "openbao-internal" "tls.crt"];
                        tls_key_file = ["/openbao/pki" "openbao-internal" "tls.key"];
                        tls_ca_file = ["/openbao/pki" "openbao-internal" "ca.crt"];
                      };
                  }
                  #TODO {% if tarook_openbao_ingress %}
                  #TODO         listener "tcp" {
                  #TODO           address = "[::]:${toString port+50}" # 8250
                  #TODO           tls_cert_file = "/openbao/pki/openbao-external/tls.crt"
                  #TODO           tls_key_file  = "/openbao/pki/openbao-external/tls.key"
                  #TODO         }
                  #TODO {% endif %}
                ]);

                storage."raft" = {
                  path = "/openbao/data";

                  # NOTE: Default generated in cfg.helm_finalValues
                  #retry_join.leader_api_addr

                  # NOTE: Default generated in cfg.helm_finalValues
                  #retry_join.leader_ca_cert_file
                };

                telemetry =
                  {
                    metrics_prefix = "openbao";
                  }
                  # Configure Prometheus specific telemetry if Prometheus is deployed
                  // lib.optionalAttrs config.yk8s.k8s-service-layer.prometheus.install {
                    prometheus_retention_time = lib.mkDefault "24h";
                  };
                # Make OpenBao apply labels about its state to its Kubernetes Pods
                # This is useful in general and required in particular
                # for cfg.helm.values.server.service.{active,standby}.enabled=true
                # NOTE: Service registration is only available
                #       when OpenBao is running in High Availability mode.
                #       (https://openbao.org/docs/2.3.x/configuration/service-registration/kubernetes/)
                service_registration =
                  lib.optionalAttrs cfg.helm.values.server.ha.enabled {
                    "kubernetes" = {};
                  };
              };
          };

          disruptionBudget.enabled = true;
        };

        # Create Kubernetes service account if OpenBao needs to register with Kubernetes
        serviceAccount = {
          create =
            if
              lib.hasAttrByPath
              ["server" "ha" "raft" "config" "service_registration" "kubernetes"]
              cfg.helm.values
            then true
            else false;
        };
      };

      # Do not create a Kubernetes Service for the OpenBao UI,
      # force off if the UI is not enabled at all
      ui.enabled =
        (
          if ! cfg.helm.values.server.ha.raft.config.ui
          then lib.mkForce
          else lib.mkDefault
        )
        false;
# TODO: The following produces infinite-recursion
#       It is unclear whether it is really needed
#    }
#    # Deploy a ServiceMonitor for OpenBao
#    # if Prometheus integration is enabled
#    // lib.optionalAttrs (
#      cfg.helm.values.global.serverTelemetry.prometheusOperator or false
#    ) {
#      serverTelemetry = {
#        # TODO: Ensure that Prometheus is deployed before OpenBao
#        # TODO: Test if we can use this instead of our own setup
#        serviceMonitor = {
#          enabled = true;
#        };
#        # REVIEW:
#        # Do we need to enable this?
#        # It is enabled in k8s-supplements/ansible/roles/vault_v1/templates/vault.yaml.j2
#        # prometheusRules = {
#        #   enabled = true;
#        # };
#      };
    };

  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.assertions = [];

  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "openbao_on_k8s";
      inventory_path = "all/openbao-on-k8s.yaml";
      unflat = "all";
      transformations = [
        # Rename helm.finalValues to helm.values
        (c: lib.pipe c [
          (c: (lib.recursiveUpdate c {helm.values = c.helm_finalValues;}))
          (c: (removeAttrsByPath c [["helm_finalValues"]]))
        ])
      ];
    })
  ];
}
