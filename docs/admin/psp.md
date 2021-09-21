## Troubleshooting

### The PSP is not effective!

If everything gets started with kube-system-privileged-psp, the
the service accounts used for that are privileged. Note that pods created by
daemonsets or jobs etc. are spawned with either the serviceAccount of the
respective controller (e.g. job-controller in kube-system for jobs), the
serviceAccount specified in the YAML or the default service account of the
target namespace.

### Pods are not being created

Check `kubectl get events -n $namespace` for details.
