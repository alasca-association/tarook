# ch-managed-k8s-docker

This Nix expression builds the container image used in the GitLab CI.

It can be manually built by running `nix build .#ciImage` from inside the LCM directory. The resulting image is a `.tar.gz` file that is linked to `./result` and can be loaded with eg. `docker load < ./result`. A more efficient approach is to stream it directly with `nix run .#streamCiImage | docker load`.

Note that the features `nix-command` and `flakes` need to be enabled as described in the [installation guide](https://yaook.gitlab.io/k8s/devel/user/guide/initialization.html). Alternatively, the command can be run with `nix run --extra-experimental-features nix-command --extra-experimental-features flakes ...`.

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
