{lib}: {
  mkTolerations = {scheduling_key ? null}:
    lib.optionals (scheduling_key != null) [
      {
        "key" = scheduling_key;
        "operator" = "Exists";
        "effect" = "NoSchedule";
      }
      {
        "key" = scheduling_key;
        "operator" = "Exists";
        "effect" = "NoExecute";
      }
    ];

  mkAffinity = {
    scheduling_key ? null,
    pod_affinity_key ? null,
    pod_affinity_operator ? "Exists",
    pod_affinity_values ? [],
  }:
    (lib.optionalAttrs (scheduling_key != null) {
      "nodeAffinity" = {
        "requiredDuringSchedulingIgnoredDuringExecution" = {
          "nodeSelectorTerms" = [
            {
              "matchExpressions" = [
                {
                  "key" = scheduling_key;
                  "operator" = "Exists";
                }
              ];
            }
          ];
        };
      };
    })
    // (lib.optionalAttrs (pod_affinity_key != null) {
      "podAffinity" = {
        "requiredDuringSchedulingIgnoredDuringExecution" = [
          {
            "labelSelector" = {
              "matchExpressions" = [
                {
                  "key" = pod_affinity_key;
                  "operator" = pod_affinity_operator;
                  "values" = pod_affinity_values;
                }
              ];
            };
            "topologyKey" = "kubernetes.io/hostname";
          }
        ];
      };
    });
}
