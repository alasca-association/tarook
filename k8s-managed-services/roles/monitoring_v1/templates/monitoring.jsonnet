{% set generate_psp = k8s_use_podsecuritypolicies %}
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

local grafanaCustomerVolumes = {
  volumes+: [
    {
      "configMap" : {
        "name" : {{ monitoring_grafana_customer_dashboards_configmap | to_json }}
      },
      "name" : "grafana-customer-dashboards"
    },
  ],
};


local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-kubeadm.libsonnet') +
  // Uncomment the following imports to enable its patches
  (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
{% if monitoring_use_thanos | bool %}
  (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
{% endif %}
{% if monitoring_prometheus_monitor_all_namespaces | bool %}
  (import 'kube-prometheus/kube-prometheus-all-namespaces.libsonnet') +
{% endif %}
  {
    _config+:: {
      namespace: '{{ monitoring_namespace }}',

      prometheus+:: {
        replicas: {{ monitoring_prometheus_replicas }}
      },
      versions+:: {
        prometheusAdapter: '{{ monitoring_prometheus_adapter_version }}',
        grafana: '{{ monitoring_grafana_version }}',
      },

      grafana+:: {

        plugins+: {{ monitoring_grafana_plugins }},
        datasources+:: [
{% if monitoring_use_thanos | bool %}
          {
            name: 'thanos',
            type: 'prometheus',
            access: 'proxy',
            orgId: 1,
            url: 'http://thanos-query.{{ monitoring_namespace }}.svc:9090',
            version: 1,
            editable: false,
          },
{% endif %}
        ],
        container: {
          {% call resource_constraints(
  monitoring_grafana_memory_request,
  monitoring_grafana_cpu_request,
  monitoring_grafana_memory_limit,
  monitoring_grafana_cpu_limit) %}{% endcall %}
        },
      },
    },
    grafanaDashboards+:: {
{% if k8s_storage_rook_enabled | bool %}
      'ceph-cluster.json': (import 'dashboards/ceph-cluster.json'),
      'ceph-osd.json': (import 'dashboards/ceph-osd.json'),
      'ceph-pools.json': (import 'dashboards/ceph-pools.json'),
{% endif %}
{% if monitoring_use_thanos | bool %}
      'thanos-overview.json': (import 'dashboards/thanos-overview.json'),
{% endif %}
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
                  key: '{{ managed_k8s_control_plane_key }}',
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

    prometheusAdapter+:: {
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('prometheus-adapter') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret", "emptyDir", "configMap"]) +
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
                        policyRule.withResourceNames(["prometheus-adapter"]);

        role.new() +
        role.mixin.metadata.withName("prometheus-adapter-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("prometheus-adapter-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("prometheus-adapter-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'prometheus-adapter',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
      deployment+: {
        spec+: {
          template+: {
            spec+: affinity
          },
        },
      },
    },

    prometheus+:: {
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('prometheus') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret", "emptyDir", "configMap"]) +
        podSecurityPolicy.mixin.spec.withHostPid(false) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostNetwork(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("MayRunAs").withRanges({"min": 2000, "max": 2000}) +
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
                        policyRule.withResourceNames(["prometheus"]);

        role.new() +
        role.mixin.metadata.withName("prometheus-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("prometheus-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("prometheus-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'prometheus-k8s',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
      prometheus+: {
        spec+: affinity + {
          probeSelector: {},
          probeNamespaceSelector: {},
          resources: {
{% call resource_constraints(
  monitoring_prometheus_memory_request,
  monitoring_prometheus_cpu_request,
  monitoring_prometheus_memory_limit,
  monitoring_prometheus_cpu_limit) %}{% endcall %}
          },
{% if monitoring_use_thanos | bool %}
          thanos+: {
            resources: {
{% call resource_constraints(
  monitoring_thanos_sidecar_memory_request,
  monitoring_thanos_sidecar_cpu_request,
  monitoring_thanos_sidecar_memory_limit,
  monitoring_thanos_sidecar_cpu_limit) %}{% endcall %}
            },
            image: "quay.io/thanos/thanos:{{ monitoring_thanos_sidecar_version }}",
            version: "{{ monitoring_thanos_sidecar_version }}"
          },
{% endif %}
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

    alertmanager+:: {
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('alertmanager') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret", "emptyDir", "configMap"]) +
        podSecurityPolicy.mixin.spec.withHostPid(false) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostNetwork(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("MayRunAs").withRanges({"min": 2000, "max": 2000}) +
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
                        policyRule.withResourceNames(["alertmanager"]);

        role.new() +
        role.mixin.metadata.withName("alertmanager-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("alertmanager-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("alertmanager-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'alertmanager-main',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
      alertmanager+: {
        spec+: affinity + {
          resources: {
{% call resource_constraints(
  monitoring_alertmanager_memory_request,
  monitoring_alertmanager_cpu_request,
  monitoring_alertmanager_memory_limit,
  monitoring_alertmanager_cpu_limit) %}{% endcall %}
          },
          // Make the name of the secret that is loaded by alertmanager as its configuration customizable from the outside.
          // This ensures that changes to the config made by the customer aren't overwritten.
          // TODO: Once AlertmanagerConfig is available as CRD we don't need this hack any longer.
          // (https://github.com/prometheus-operator/prometheus-operator/pull/3451)
          configSecret: {{ monitoring_alertmanager_config_secret | to_json }},
        },
      },
      // kube-prometheus auto generates a default "alertmanager-secret" manifest. Our deployer is dumb and applies every
      // manifest that it can find to the cluster. If we're using a different secret than the default one it would be
      // applied nevertheless. Hence two alertmanager secrets would appear in the cluster although only one is used. The
      // customer would have to check which secret is actually mounted to edit the right one. By setting the secret to ""
      // if we're using a custom one, it is not (re-) added to the cluster.
      // NOTE: we're basically working against kube-prometheus. The AlertmanagerConfig CRD will also make this snippet
      // obsolete.
      {% if monitoring_alertmanager_config_secret != "alertmanager-main" %}
      secret: ""
      {% endif %}
    },

    grafana+:: {
{% if generate_psp | bool %}
      "00-podSecurityPolicy":
        local podSecurityPolicy = k.policy.v1beta1.podSecurityPolicy;

        podSecurityPolicy.new() +
        podSecurityPolicy.mixin.metadata.withName('grafana') +
        podSecurityPolicy.mixin.metadata.withNamespace($._config.namespace) +
        podSecurityPolicy.mixin.spec.withPrivileged(false) +
        podSecurityPolicy.mixin.spec.withAllowPrivilegeEscalation(false) +
        podSecurityPolicy.mixin.spec.withVolumes(["secret", "emptyDir", "configMap"]) +
        podSecurityPolicy.mixin.spec.withHostPid(false) +
        podSecurityPolicy.mixin.spec.withHostIpc(false) +
        podSecurityPolicy.mixin.spec.withHostNetwork(false) +
        podSecurityPolicy.mixin.spec.fsGroup.withRule("RunAsAny").withRanges({"min": 1, "max": 65535}) +
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
                        policyRule.withResourceNames(["grafana"]);

        role.new() +
        role.mixin.metadata.withName("grafana-psp") +
        role.mixin.metadata.withNamespace($._config.namespace) +
        role.withRules([pspRule]),

      "00-pspRoleBinding":
        local roleBinding = k.rbac.v1.roleBinding;

        roleBinding.new() +
        roleBinding.mixin.metadata.withName("grafana-psp") +
        roleBinding.mixin.metadata.withNamespace($._config.namespace) +
        roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
        roleBinding.mixin.roleRef.withName("grafana-psp") +
        roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
        roleBinding.withSubjects([
          {
            kind: 'ServiceAccount',
            name: 'grafana',
            namespace: $._config.namespace
          }
        ]),
{% endif %}
      deployment+: {
        spec+: {
          template+: {
            spec+: affinity + grafanaCustomerVolumes
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

local kp_with_patched_grafana = kp + {
  grafana+: {
    // This is an ugly hack because it completely overwrites the dashboardSources
    // It's necessary to pass the 'foldersFromFileStructure' parameter to the provider
    {% if monitoring_grafana_customer_dashboards | bool %}
        dashboardSources: {
           "apiVersion": "v1",
           "data": {
              "dashboards.yaml": "{\n    \"apiVersion\": 1,\n    \"providers\": [\n        {\n            \"folder\": \"Default\",\n            \"name\": \"0\",\n            \"options\": {\n                \"path\": \"/grafana-dashboard-definitions/0\"\n            },\n            \"orgId\": 1,\n            \"type\": \"file\"\n        },\n        {\n            \"folder\": \"Customer-Dashboards\",\n            \"name\": \"Customer-Dashboards\",\n            \"options\": {\n                \"path\": \"/grafana-dashboard-definitions/Customer-Dashboards\"\n            },\n            \"orgId\": 1,\n            \"type\": \"file\",\n\"foldersFromFileStructure\": true\n        }\n    ]\n}"
           },
           "kind": "ConfigMap",
           "metadata": {
              "name": "grafana-dashboards",
              "namespace": "monitoring"
           }
         },
    {% endif %}
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: [
                container + {
                {% if monitoring_grafana_customer_dashboards | bool %}
                  volumeMounts+: [
                    {
                      "mountPath": "/grafana-dashboard-definitions/Customer-Dashboards",
                      "name" : "grafana-customer-dashboards",
                      "readOnly" : false
                    }

                {% endif %}
                  ]
                }
                for container in kp.grafana.deployment.spec.template.spec.containers
            ],
          }
        }
      }
    }
  }
};

// serviceMonitor is separated so that it can be created after the CRDs are ready
{ '10-prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['20-alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['20-prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['20-prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['20-grafana-' + name]: kp_with_patched_grafana.grafana[name] for name in std.objectFields(kp_with_patched_grafana.grafana) }
