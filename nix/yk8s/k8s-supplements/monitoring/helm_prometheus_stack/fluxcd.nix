{
  config,
  lib,
  ...
}: let
  integration_enabled = config.yk8s.k8s-service-layer.fluxcd.enabled && config.yk8s.k8s-service-layer.fluxcd.install;

  mkResource = {
    group,
    version,
    kind,
    labelsFromPath ? {},
    hasReadyCondition ? true,
  }: {
    groupVersionKind = {
      inherit group version kind;
    };
    metricNamePrefix = "gotk";
    metrics = [
      {
        name = "resource_info";
        help = "The current state of a Flux ${kind} resource.";
        each = {
          type = "Info";
          info.labelsFromPath.name = ["metadata" "name"];
        };
        labelsFromPath =
          {
            exported_namespace = ["metadata" "namespace"];
            suspended = ["spec" "suspend"];
          }
          // lib.optionalAttrs hasReadyCondition {
            ready = ["status" "conditions" "[type=Ready]" "status"];
          }
          // labelsFromPath;
      }
    ];
  };

  resources = map mkResource [
    {
      group = "kustomize.toolkit.fluxcd.io";
      version = "v1";
      kind = "Kustomization";
      labelsFromPath = {
        revision = ["status" "lastAppliedRevision"];
        source_name = ["spec" "sourceRef" "name"];
      };
    }
    {
      group = "helm.toolkit.fluxcd.io";
      version = "v2";
      kind = "HelmRelease";
      labelsFromPath = {
        revision = ["status" "history" "0" "chartVersion"];
        chart_name = ["status" "history" "0" "chartName"];
        chart_app_version = ["status" "history" "0" "appVersion"];
        chart_ref_name = ["spec" "chartRef" "name"];
        chart_source_name = ["spec" "chart" "spec" "sourceRef" "name"];
      };
    }
    {
      group = "source.toolkit.fluxcd.io";
      version = "v1";
      kind = "GitRepository";
      labelsFromPath = {
        revision = ["status" "artifact" "revision"];
        url = ["spec" "url"];
      };
    }
    {
      group = "source.toolkit.fluxcd.io";
      version = "v1";
      kind = "Bucket";
      labelsFromPath = {
        revision = ["status" "artifact" "revision"];
        endpoint = ["spec" "endpoint"];
        bucket_name = ["spec" "bucketName"];
      };
    }
    {
      group = "source.toolkit.fluxcd.io";
      version = "v1";
      kind = "HelmRepository";
      labelsFromPath = {
        revision = ["status" "artifact" "revision"];
        url = ["spec" "url"];
      };
    }
    {
      group = "source.toolkit.fluxcd.io";
      version = "v1";
      kind = "HelmChart";
      labelsFromPath = {
        revision = ["status" "artifact" "revision"];
        chart_name = ["spec" "chart"];
        chart_version = ["spec" "version"];
      };
    }
    {
      group = "source.toolkit.fluxcd.io";
      version = "v1";
      kind = "OCIRepository";
      labelsFromPath = {
        revision = ["status" "artifact" "revision"];
        url = ["spec" "url"];
      };
    }
    {
      group = "notification.toolkit.fluxcd.io";
      version = "v1beta3";
      kind = "Alert";
      hasReadyCondition = false;
    }
    {
      group = "notification.toolkit.fluxcd.io";
      version = "v1beta3";
      kind = "Provider";
      hasReadyCondition = false;
    }
    {
      group = "notification.toolkit.fluxcd.io";
      version = "v1";
      kind = "Receiver";
      labelsFromPath = {
        webhook_path = ["status" "webhookPath"];
      };
    }
    {
      group = "image.toolkit.fluxcd.io";
      version = "v1";
      kind = "ImageRepository";
      labelsFromPath = {
        image = ["spec" "image"];
      };
    }
    {
      group = "image.toolkit.fluxcd.io";
      version = "v1";
      kind = "ImagePolicy";
      labelsFromPath = {
        source_name = ["spec" "imageRepositoryRef" "name"];
      };
    }
    {
      group = "image.toolkit.fluxcd.io";
      version = "v1";
      kind = "ImageUpdateAutomation";
      labelsFromPath = {
        source_name = ["spec" "sourceRef" "name"];
      };
    }
  ];
in {
  # https://fluxcd.io/flux/monitoring/metrics/#monitoring-setup
  # https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/kube-prometheus-stack/kube-state-metrics-config.yaml
  config.yk8s.k8s-service-layer.prometheus.helm.values = lib.mkIf integration_enabled {
    kube-state-metrics = {
      rbac.extraRules = [
        {
          apiGroups = lib.unique (map (r: r.groupVersionKind.group) resources);
          resources = [
            "gitrepositories"
            "buckets"
            "helmrepositories"
            "helmcharts"
            "ocirepositories"
            "kustomizations"
            "helmreleases"
            "alerts"
            "providers"
            "receivers"
            "imagerepositories"
            "imagepolicies"
            "imageupdateautomations"
          ];
          verbs = ["list" "watch"];
        }
      ];
      customResourceState = {
        enabled = true;
        config.spec = {inherit resources;};
      };
    };
  };
}
