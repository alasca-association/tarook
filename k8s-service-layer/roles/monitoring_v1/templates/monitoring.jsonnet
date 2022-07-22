{% from "jsonnet-tools.j2" import resource_constraints %}
local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';

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

local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-kubeadm.libsonnet') +
  // Uncomment the following imports to enable its patches
  (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  {
    _config+:: {
      namespace: '{{ monitoring_namespace }}',
    },
      prometheus+:: {
        namespaces+: [
{% if k8s_storage_rook_enabled | bool %}
            '{{ rook_namespace }}',
{% endif %}
        ],
      },

    nodeExporter+:: {
      daemonset+: {
        spec+: {
          template+: {
            spec+: {
              // note: we only add a toleration here, not the label constraint,
              // because the node-exporter needs to run on all the nodes.
              tolerations+: [
                {
                  operator: 'Exists',
                  effect: 'NoSchedule',
                }
              ],
            }
          },
        },
      },
    },

    prometheusOperator+:: {
      // For the following resources, the creationTimestamp field is present in the
      // base files, but has the value "null". This breaks the Kubernetes validation of
      // the manifest files. Thus, the field is made hidden in the following resources.
      '0alertmanagerCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0prometheusCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0servicemonitorCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0podmonitorCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0prometheusruleCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0thanosrulerCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      '0probeCustomResourceDefinition'+: {
        metadata+: {
          creationTimestamp:: null
        },
      },

      deployment+: {
        spec+: {
          template+: {
            spec+: affinity
          },
        },
      },
    },

    kubeStateMetrics+:: {
      deployment+: {
        spec+: {
          template+: {
            spec+: affinity,
          },
        },
      },
    },

  };

// We have to play tricks to attach the resource limits to the
// kube-state-metrics, because there is no input for them and we have to patch
// all containers

local kp_with_patched_ksm = kp + {
  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
              container + {
                resources: if container.name == "kube-state-metrics" then {
  {% call resource_constraints(
  monitoring_kube_state_metrics_memory_request,
  monitoring_kube_state_metrics_cpu_request,
  monitoring_kube_state_metrics_memory_limit,
  monitoring_kube_state_metrics_cpu_limit) %}{% endcall %}
                } else {
                  limits: {
                    cpu: "20m",
                    memory: "40Mi",
                  },
                  requests: {
                    cpu: "10m",
                    memory: "20Mi",
                  },
                }
              }
              for container in kp.kubeStateMetrics.deployment.spec.template.spec.containers
            ]
          }
        }
      }
    }
  }
};

local kp_with_patched_node_exporter = kp + {
  nodeExporter+: {
    daemonset+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
              container + {"args" :
                container["args"] + (
                  if container.name == "node-exporter" then
                    [
                      "--collector.textfile.directory=/host/root/{{ monitoring_node_exporter_textfile_collector_path }}",
                      "--collector.textfile"
                    ]
                  else []
                )
              }
              for container in kp.nodeExporter.daemonset.spec.template.spec.containers
            ],
          }
        }
      }
    }
  }
};

{
  ['01-prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
{ ['20-node-exporter-' + name]: kp_with_patched_node_exporter.nodeExporter[name] for name in std.objectFields(kp_with_patched_node_exporter.nodeExporter) } +
{ ['20-kube-state-metrics-' + name]: kp_with_patched_ksm.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) }
