# Prometheus

yaook/k8s uses the kube-prometheus-stack helm chart with an additional abstraction layer. To figure out the version, you could use `helm ls -n monitoring`. Take a look at the `values.yaml` files of the individual helm charts to see what you can (or cannot) potentially modified. Note that not all values might be exposed in the `config.toml`. The data path is `config.toml -> inventory/prometheus.yaml -> monitoring_v2 -> templates/prometheus_stack.yaml.j2`. If a field that you need isn't listed in `prometheus_stack.yaml` or statically configured, please [open an issue](https://gitlab.com/yaook/k8s/-/issues) or, even preferable, [submit a merge request :)](https://gitlab.com/yaook/k8s/-/merge_requests). yaook/k8s' developer guide can be found [here.](https://yaook.gitlab.io/meta/01-developing.html#workflow)

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
