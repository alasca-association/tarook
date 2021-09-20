# Cluster Repository

The cluster repository is a git repository. It holds all information which
define the (intended) state of a cluster. This information consists of:

- The version of the LCM code to deploy the cluster
- The version of the WireGuard user information
- State of Terraform
- State of the WireGuard IP address management (IPAM)
- Secrets and credentials obtained while deploying the cluster
- A configuration file which defines the platform layout and other properties
  of the cluster
