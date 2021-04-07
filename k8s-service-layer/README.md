# Kubernetes Service Layer

This ansible playbook directory provides the service layer of the Kubernetes
cluster. It sits between the bare-bones Kubernetes layer and the value-added
managed-k8s layer (if any).

It provides the following extensions to the standard Kubernetes API:

- Certificate management (`cert-manager.io/v1`)
- Ingress (`networking.k8s.io/v1beta1`)
- Prometheus management (kube-prometheus, various APIs)
