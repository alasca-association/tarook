# Prometheus

yaook/k8s uses the kube-prometheus-stack helm chart with an additional abstraction layer. To figure out the version, you could use `helm ls -n monitoring`. Take a look at the `values.yaml` files of the individual helm charts to see what you can (or cannot) potentially modified. Note that not all values might be exposed in the `config.toml`. The data path is `config.toml -> inventory/prometheus.yaml -> monitoring_v2 -> templates/prometheus_stack.yaml.j2`. If a field that you need isn't listed in `prometheus_stack.yaml` or statically configured, please [open an issue](https://gitlab.com/yaook/k8s/-/issues) or, even preferable, [submit a merge request :)](https://gitlab.com/yaook/k8s/-/merge_requests). yaook/k8s' developer guide can be found [here.](https://yaook.gitlab.io/meta/01-developing.html#workflow)
yaook/k8s also allows the upgrade of this kube-prometheus-stack. The upgrade routine can be triggered by changing the value of `monitoring_prometheus_stack_version` in `monitoring_v2 -> defaults/main.yaml`. Currently it supports upgrade from version 33.x to 39.x.

## Grafana

The LCM uses the [Grafana helm chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana) with the version that comes with the current kube-prometheus-stack helm chart version.

### Custom dashboards and datasources

By default, Grafana will be rolled with two sidecars (`grafana-sc-dashboard`, `grafana-sc-datasources`) that are configured to pick up *additional* dashboards/datasources in *any* namespace. These extra resources can reside either in k8s `Secrets` or in `ConfigMaps`. They have to have a label `grafana_dashboard` set. To configure a custom, *logical* folder for one or more dashboard, add the annotation `customer-dashboards=<Folder name>`. **Note**: After 30s seconds of research the author came to the conclusion that one cannot nest logical dashboard folders in Grafana. If `<Folder name>` consists of a path of multiple folders, only the last one is picked.

As an example, let's add a dashboard for the NGINX Ingress Controller and have it displayed under the logical `nginx` folder in Grafana. The backing configmap for the dashboard should be stored in the namespace `fancy`.

1. Download the dashboard as [JSON](https://grafana.com/grafana/dashboards/9614?pg=dashboards&plcmt=featured-dashboard-4) to your workstation. We will call that manifest `nginx_db.json`.
2. Create the configmap: `kubectl create configmap nginx-db -n fancy --from-file=nginx_db.json`
3. Add a label so that the sidecar will pick up the dashboard: `kubectl label cm -n fancy nginx-db grafana_dashboard=1`. (The value of the key/value label pair does not matter)
4. Annotate the configmap with the proper path: `kubectl annotate cm -n fancy nginx-db customer-dashboards=nginx`.

The sidecar should pick up the change eventually. If it doesn't or you're impatient, you could restart Grafana by destroying its pod.

## Alertmanager

The monitoring stack comes with an alertmanager instance that is available to the end user for their convenience. One can create also their own `Alertmanager` resource which is then translated into a `StatefulSet` by the prometheus operator. AM configuration should be kept separate and can be injected by creating a `AlertmanagerConfig` resource within the `monitoring` namespace. Other namespace are not considered without further configuration. For further information please refer to the [corresponding documentation.](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/alerting.md) A silly example:

```
kind: AlertmanagerConfig
apiVersion: monitoring.coreos.com/v1alpha1
metadata:
  name: custom-amc
  namespace: monitoring
spec:
  receivers:
    - name: your mom
      emailConfigs:
        - hello: localhost
          requireTLS: true
          to: a@b.de
          smarthost: a.com:25
          from: c@d.de
      pagerdutyConfigs:
        - url: https://events.pagerduty.com/v2/enqueue
          routingKey:
            key: a
            name: blub
            optional: true
  route:
    receiver: your mom
    groupBy:
    - job
    continue: false
    routes:
    - receiver: your mom
      match:
        alertname: Watchdog
      continue: false
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
```

Note 1: The author hasn't worked much with `Alertmanager(Config)` in the past and only ensured that manifests are read correctly. Their test was looking at `k exec -ti -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -- amtool --alertmanager.url=http://127.0.0.1:9093 config`.

Note 2: You will probably mess up the `AlertmanagerConfig` manifest in one way or another. The AdmissionController caught some typos. On other occasions I had to look into the logs of the `prometheus-operator` pod. And eventually the AM failed to come up because I missed some further fields which I figured via the logs of the `AM` pod.

## Thanos

Thanos is deployed outside of the kube-prometheus-stack helm chart. By default, it writes its metrics into a SWIFT object storage container that resides in the same OpenStack project.

**TODO:** Add more information, e.g., on `thanos compact`.

> ***Warning:*** If you want to use application credentials, then you have to disable the thanos monitoring component (`use_thanos = false`) for now. See [here](https://gitlab.com/yaook/k8s/-/issues/436#note_873556688) for more context.
