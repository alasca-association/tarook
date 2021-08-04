{% set generate_psp = k8s_use_podsecuritypolicies | default(False) %}
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
{% if rook | bool %}
            '{{ rook_namespace }}',
{% endif %}
        ],
      },

    nodeExporter+:: {
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('node-exporter') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostPid(true) +
        podSecurityPolicy.mixin.spec.withHostNetwork(true) +
        podSecurityPolicy.mixin.spec.withHostPorts([
          {
            min: 9100,
            max: 9100,
          }
        ]) +
        podSecurityPolicy.mixin.spec.withVolumes(["hostPath", "secret"]) +
        podSecurityPolicy.mixin.spec.withAllowedHostPaths([
          {
            pathPrefix: "/",
            readOnly: true,
          },
          {
            pathPrefix: "/proc",
            readOnly: false,
          },
          {
            pathPrefix: "/sys",
            readOnly: false,
          },
        ]) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("RunAsAny") +
        podSecurityPolicy.mixin.spec.supplementalGroups.withRule("MayRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.runAsGroup.withRule("MustRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.runAsUser.withRule("MustRunAsNonRoot") +
        podSecurityPolicy.mixin.spec.seLinux.withRule("RunAsAny"),

      "00-pspRole":
        local role = k.rbac.v1.role;
        local policyRule = role.rulesType;

        local pspRule = policyRule.new() +
                        policyRule.withApiGroups(["policy"]) +
                        policyRule.withVerbs(["use"]) +
                        policyRule.withResources(["podsecuritypolicies"]) +
                        policyRule.withResourceNames(["node-exporter"]);

        role.new() +
        role.mixin.metadata.withName("node-exporter-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("node-exporter-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("node-exporter-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'node-exporter',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
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
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('prometheus-operator') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret"]) +
        podSecurityPolicy.mixin.spec.withHostPid(false) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostNetwork(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("RunAsAny") +
        podSecurityPolicy.mixin.spec.runAsUser.withRule("MustRunAsNonRoot") +
        podSecurityPolicy.mixin.spec.supplementalGroups.withRule("MayRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.runAsGroup.withRule("MustRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.seLinux.withRule("RunAsAny"),

      "00-pspRole":
        local role = k.rbac.v1.role;
        local policyRule = role.rulesType;

        local pspRule = policyRule.new() +
                        policyRule.withApiGroups(["policy"]) +
                        policyRule.withVerbs(["use"]) +
                        policyRule.withResources(["podsecuritypolicies"]) +
                        policyRule.withResourceNames(["prometheus-operator"]);

        role.new() +
        role.mixin.metadata.withName("prometheus-operator-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("prometheus-operator-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("prometheus-operator-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'prometheus-operator',
            namespace: $._config.namespace
          }
        ]),
{% endif %}

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
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('kube-state-metrics') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret"]) +
        podSecurityPolicy.mixin.spec.withHostPid(false) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostNetwork(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("RunAsAny") +
        podSecurityPolicy.mixin.spec.runAsUser.withRule("MustRunAsNonRoot") +
        podSecurityPolicy.mixin.spec.supplementalGroups.withRule("MayRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.runAsGroup.withRule("MustRunAs").withRanges({"min": 1, "max": 65535}) +
        podSecurityPolicy.mixin.spec.seLinux.withRule("RunAsAny"),

      "00-pspRole":
        local role = k.rbac.v1.role;
        local policyRule = role.rulesType;

        local pspRule = policyRule.new() +
                        policyRule.withApiGroups(["policy"]) +
                        policyRule.withVerbs(["use"]) +
                        policyRule.withResources(["podsecuritypolicies"]) +
                        policyRule.withResourceNames(["kube-state-metrics"]);

        role.new() +
        role.mixin.metadata.withName("kube-state-metrics-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("kube-state-metrics-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("kube-state-metrics-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'kube-state-metrics',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
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
