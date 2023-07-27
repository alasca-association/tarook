{% from "jsonnet-tools.j2" import resource_constraints, set_common_labels %}
local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';
local sts = k.apps.v1.statefulSet;
local deployment = k.apps.v1.deployment;
local t = (import 'kube-thanos/thanos.libsonnet');

local commonConfig = {
  config+:: {
    local cfg = self,
    namespace: '{{ monitoring_namespace }}',
    version: '{{ monitoring_thanos_version }}',
    image: 'quay.io/thanos/thanos:' + cfg.version,
    objectStorageConfig: {
      name: 'thanos-objectstorage',
      key: 'thanos.yaml',
    },
    volumeClaimTemplate: {
      spec: {
        accessModes: ['ReadWriteOnce'],
        resources: {
          requests: {
            storage: '{{ monitoring_thanos_metadata_volume_size }}',
          },
        },
        storageClassName: '{{ monitoring_thanos_metadata_volume_storage_class }}',
      },
    },
  },
};

local tolerations = {
{% if monitoring_scheduling_key %}
  tolerations+: [{
    key: {{ monitoring_scheduling_key | to_json }},
    operator: 'Exists',
    effect: 'NoExecute',
  }, {
    key: {{ monitoring_scheduling_key | to_json }},
    operator: 'Exists',
    effect: 'NoSchedule',
  }],
{% endif %}
};

local affinity = {
  affinity+: {
{% if monitoring_scheduling_key %}
    nodeAffinity+: {
      requiredDuringSchedulingIgnoredDuringExecution+: {
        nodeSelectorTerms+: [
          {
            matchExpressions+: [{
              key: {{ monitoring_scheduling_key | to_json }},
{% if monitoring_scheduling_value %}
              operator: 'Equals',
              value: {{ monitoring_scheduling_value | to_json }},
{% else %}
              operator: 'Exists',
{% endif %}
            }]
          }
        ]
      }
    }
{% endif %}
  },
} + tolerations;

local c = t.compact + t.compact.withVolumeClaimTemplate + t.compact.withServiceMonitor + t.compact.withRetention + t.compact.withResources + commonConfig + {
  config+:: {
    name: 'thanos-compact',
{{ set_common_labels(monitoring_common_labels) }}
    replicas: 1,
    retentionResolutionRaw: '{{ monitoring_thanos_retention_resolution_raw }}',
    retentionResolution5m: '{{ monitoring_thanos_retention_resolution_5m }}',
    retentionResolution1h: '{{ monitoring_thanos_retention_resolution_1h }}',
    resources: {
      {% call resource_constraints(
        monitoring_thanos_compact_memory_request,
        monitoring_thanos_compact_cpu_request,
        monitoring_thanos_compact_memory_limit,
        monitoring_thanos_compact_cpu_limit) %}{% endcall %}
    },
  },
  statefulSet+: {
    spec+: {
      template+: {
        spec+: affinity {
          volumes: [],  // Added to pass the Kubernetes validation
        }
      }
    }
  },
};

local patched_compact = c + {
  statefulSet+: {
    spec+: {
      template+: {
        spec+: affinity {
          containers: [
            container + {"args" :
              container["args"] + (
                if container.name == "thanos-compact" then [
                  "--delete-delay=2h"
                ] else []
              )
            }
            for container in c.statefulSet.spec.template.spec.containers
          ]
        }
      }
    }
  },
};

local s = t.store + t.store.withVolumeClaimTemplate + t.store.withServiceMonitor + t.store.withResources + commonConfig + {
  config+:: {
    name: 'thanos-store',
{{ set_common_labels(monitoring_common_labels) }}
    replicas: 1,
    resources: {
      {% call resource_constraints(
        monitoring_thanos_store_memory_request,
        monitoring_thanos_store_cpu_request,
        monitoring_thanos_store_memory_limit,
        monitoring_thanos_store_cpu_limit) %}{% endcall %}
    },
  },

  statefulSet+: {
    spec+: {
      template+: {
        spec+: affinity {
          volumes: [],  // Added to pass the Kubernetes validation
        }
      }
    }
  },
};

local q = t.query + t.query.withServiceMonitor + t.query.withResources + commonConfig + {
  config+:: {
    name: 'thanos-query',
{{ set_common_labels(monitoring_common_labels) }}
    replicas: 1,
    stores: [
      'dnssrv+_grpc._tcp.%s.%s.svc.cluster.local' % [s.service.metadata.name, s.service.metadata.namespace]
    ] + [
      'dnssrv+_grpc._tcp.{{ monitoring_prometheus_service_name }}.monitoring.svc.cluster.local'
    ] + [
{% for endpoint in monitoring_thanos_query_additional_store_endpoints %}
      'dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local',
{% endfor %}
    ],
    replicaLabels: ['prometheus_replica', 'rule_replica'],
    resources: {
      {% call resource_constraints(
        monitoring_thanos_query_memory_request,
        monitoring_thanos_query_cpu_request,
        monitoring_thanos_query_memory_limit,
        monitoring_thanos_query_cpu_limit) %}{% endcall %}
    },
  },

  deployment+: {
    spec+: {
      template+: {
        spec+: affinity
      }
    }
  },
};

{ ['thanos-compact-' + name]: patched_compact[name] for name in std.objectFields(c) } +
{ ['thanos-store-' + name]: s[name] for name in std.objectFields(s) } +
{ ['thanos-query-' + name]: q[name] for name in std.objectFields(q) }
