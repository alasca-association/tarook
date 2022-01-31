{% from "jsonnet-tools.j2" import resource_constraints %}
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

//local b = t.bucket + commonConfig + {
//  config+:: {
//    name: 'thanos-bucket',
//    replicas: 1,
//  },
//};
//
local c = t.compact + t.compact.withVolumeClaimTemplate + t.compact.withServiceMonitor + t.compact.withRetention + t.compact.withResources + commonConfig + {
  config+:: {
    name: 'thanos-compact',
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

//
//local re = t.receive + t.receive.withVolumeClaimTemplate + t.receive.withServiceMonitor + commonConfig + {
//  config+:: {
//    name: 'thanos-receive',
//    replicas: 1,
//    replicationFactor: 1,
//  },
//};
//
//local ru = t.rule + t.rule.withVolumeClaimTemplate + t.rule.withServiceMonitor + commonConfig + {
//  config+:: {
//    name: 'thanos-rule',
//    replicas: 1,
//  },
//};

local s = t.store + t.store.withVolumeClaimTemplate + t.store.withServiceMonitor + t.store.withResources + commonConfig + {
  config+:: {
    name: 'thanos-store',
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
    replicas: 1,
    stores: [
      'dnssrv+_grpc._tcp.%s.%s.svc.cluster.local' % [service.metadata.name, service.metadata.namespace]
      for service in [s.service]
    ] + [
      'dnssrv+_grpc._tcp.{{ monitoring_prometheus_service_name }}.monitoring.svc.cluster.local'
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

//local finalRu = ru {
//  config+:: {
//    queriers: ['dnssrv+_http._tcp.%s.%s.svc.cluster.local' % [q.service.metadata.name, q.service.metadata.namespace]],
//  },
//};

//{ ['thanos-bucket-' + name]: b[name] for name in std.objectFields(b) } +
{ ['thanos-compact-' + name]: patched_compact[name] for name in std.objectFields(c) } +
//{ ['thanos-receive-' + name]: re[name] for name in std.objectFields(re) } +
//{ ['thanos-rule-' + name]: finalRu[name] for name in std.objectFields(finalRu) } +
{ ['thanos-store-' + name]: s[name] for name in std.objectFields(s) } +
{ ['thanos-query-' + name]: q[name] for name in std.objectFields(q) }