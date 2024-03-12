# ch-managed-k8s-docker

This repository builds the docker image used in the GitLab CI for the
https://gitlab.com/yaook/k8s repository.

For successful use, it is required that the following prerequisites
are fulfilled:

- The `OS_PASSWORD` environment variable is set to a password which is
  valid for the user referenced in the `openrc.sh`.

- A valid wireguard private key which also matches the public key
  provided in the cluster config is put to the path contained in the
  environment variable `wg_private_key_file`. This environment
  variable is set by the image.

- An SSH private key which matches the public key stored in OpenStack
  under the name stored in the `TF_VAR_keypair` for the user referenced
  in the `openrc.sh` needs to be placed in `/root/.ssh/id_rsa`.

  The private key must be in legacy PEM format.
