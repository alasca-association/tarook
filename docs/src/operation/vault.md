# Use of HashiCorp Vault in yaook/k8s

<!-- This file uses https://rhodesmill.org/brandon/2012/one-sentence-per-line/ -->

As of Summer 2022, yaook/k8s exclusively supports [HashiCorp Vault](https://vaultproject.io) as backend for storing secrets.
Previously, passwordstore was used.
Vault supports many different kinds of secrets
and in particular its support for managing PKIs made it attractive for yaook/k8s.

A Vault instance can be the backend for one or more yaook/k8s clusters;
it is not required that each cluster has a separate Vault.
It is also possible to use the Vault instance for something else in addition to hosting yaook/k8s clusters,
though this is not recommended to avoid accidental exposure of credentials.

## Vault primer

If you are already familiar with Vault, you can skip this section.

Vault is a secret storage engine.
Secrets are organized in so-called secrets engines.
Each engine manages a different type of secret.
For yaook/k8s, the three most important secret engines are:

- [SSH CA/Certificate management](https://www.vaultproject.io/docs/secrets/ssh) (`ssh`)
- [Public-Key Infrastructure CA/Certificate management](https://www.vaultproject.io/docs/secrets/pki) (`pki`)
- [Generic Key/Value](https://www.vaultproject.io/docs/secrets/kv/kv-v2) (`kv`, version 2)

Secrets are accessed via HTTPS.
Secrets engines are mounted at a URL path,
so that everything at and below the mount point is handled by that secrets engine.

For example, if we mount a `kv` engine at `foo/` and an `ssh` engine at `bar/`
then `https://vault-server/foo/xyz` is handled by the `kv` engine
and `https://vault-server/bar/baz` is handled by the `ssh` engine.
Any other path would cause a 404 (with exceptions, see below).

In addition to secrets engines you mounted,
Vault also has some internal endpoints,
as well as the `auth/` prefix under which authentication methods live.

Authentication methods can, like secrets engines, be used in a very modular fashion.
For yaook/k8s, the [`approle`](https://www.vaultproject.io/docs/auth/approle) method is most important.
It allows to create role/secret pairs,
which are functionally identical to a username/password pair.
These are intended to be used by machine accounts
and in yaook/k8s they are used to give each node a unique credential.

Access to data in Vault,
including authentication configuration,
happens via HTTPS calls.
The actions on an item (create, update, delete) are distinguished using standard HTTP methods (GET, POST, DELETE).
The access control is based on policies,
which in turn grant access to specific HTTP methods on paths.
That way, very fine grained access control is possible,
even down into specific parts of a secret engine.

## Organization of Data in Vault

All secrets engines used by yaook/k8s are mounted below the `yaook/` path
prefix.
(This prefix is configurable, but that is not well-tested.)
Each cluster gets its own secrets engines,
to improve the isolation between different clusters.
The per-cluster secrets engines are mounted at `yaook/$cluster_name/...`,
where `$cluster_name` is configured in `config.toml` (`vault.cluster_name`).

The following six secrets engines are used:

- `yaook/$cluster_name/kv`, a KV2 engine for generic secrets
  (wireguard key, service account signing key, ...)
- `yaook/$cluster_name/k8s-pki`, a CA to issue identities within the Kubernetes cluster
  (e.g. API server, nodes)
- `yaook/$cluster_name/k8s-front-proxy-pki`, a CA to prove the identity of the Kubernetes API server
  for API extensions
- `yaook/$cluster_name/etcd-pki`, a CA to issue identities within the etcd cluster
  (e.g. cluster peers, clients)
- `yaook/$cluster_name/calico-pki`, a CA to issue identities within calico
  (typha and nodes)
- `yaook/$cluster_name/ssh-ca`, an SSH certificate authority to allow verifying node SSH keys
  without prior knowledge

In addition to the secrets engines,
yaook/k8s has a shared `approle` authentication method at `yaook/nodes`.
This auth method is used to provide credentials
for the individual nodes of all clusters.

## Vault UI

Vault comes with a web user interface.
In order to access the web interface,
enter the cluster repository and run:

```console
$ sensible-browser "$VAULT_ADDR/ui/"
```

The `VAULT_ADDR` environment variable is automatically provided
if you have `actions/vault_env.sh` sourced in your `.envrc`,
as is recommended.
`sensible-browser` is a Debian-ism.
On non-Debian distributions,
you may want to `echo "$VAULT_ADDR/ui/"` instead
and just open that link.

After opening the web UI page,
you need to log in.
You can log in as root
using the root token.
The root token can be displayed using:

```console
$ echo "$VAULT_TOKEN"
```

Or copied into the (X) clipboard using
(does not work on Wayland,
most likely):

```console
$ echo "$VAULT_TOKEN" | xsel -bi
```

## On the use of Ed25519 keys

By default,
all scripts in this repository generate Ed25519 key pairs
for CA-level keys.

The reason for this is that elliptic curve keys are generally smaller
and thus easier to store offline,
if your policies require such treatment.
Ed25519 is preferred over NIST-ECDSA,
simply because based on implementation issues in the recent years
it seems to be the more robust algorithm for long-term must-not-be-exposed secrets.

The downside is that this renders the setup incompatible with Ubuntu versions
older than 20.04 LTS
(and probably other operating systems)
due to lack of support in the respective `python3-cryptography` package.

## On policies

The `vault/init.sh` script (see below) creates Vault policies
which are used for and by the LCM.
There are separate policies for k8s nodes, k8s control plane nodes, gateway
nodes, common nodes and the orchestrator.

All except the orchestrator role are used by machines provisioned by the LCM.
The orchestrator role is designed to be used to *run* and use the LCM.
It has sufficient privileges to execute all scripts listed below,
except the `init.sh` script,
but including the `mkcluster-*.sh` and `import.sh` scripts.

Hence, this role is rather powerful,
but it's still better than a root token.

Using a token or approle account with the orchestrator role
is the recommended way to invoke the LCM.
For development setups,
the LCM defaults to running with the root token.

To run the LCM with a custom token,
set the `VAULT_TOKEN` environment variable.
To run the LCM with a custom approle,
set the `VAULT_AUTH_PATH`, `VAULT_AUTH_METHOD=approle`, `VAULT_ROLE_ID` and `VAULT_SECRET_ID` environment variables (see also [Vault tooling variables](../usage/environmental-variables.md#vault-tooling-variables)).

**Note:** Currently, only `approle` is supported as an auth method besides `token`.
Additional auth methods could be implemented as needed.

**Note:** The approle-related environment variables described above are only supported by the ansible LCM.
They are not supported by the `vault` CLI tool or the vault scripts.
To use different privileges with those,
manually log into Vault using the CLI
and export the resulting token via the `VAULT_TOKEN` environment variable.

## Managing Clusters in Vault

The following scripts are provided in order to manage a Vault instance for yaook/k8s.

Please see [Vault tooling variables](../usage/environmental-variables.md#vault-tooling-variables)
for additional environment variables accepted by these tools.

- `tools/vault/init.sh`:
    Create policies and initialize the shared approle auth method.
    This will generally require a very privileged Vault entity
    (possibly a root token)
    to run and needs to be executed only once
    (and on policy updates).

- `tools/vault/mkcluster-root.sh CLUSTERNAME`:
    Prepare a new cluster inside Vault,
    putting the root CA keys inside Vault.
    That means that control over vault implies permanent
    (until the Root CAs have been exchanged)
    control over the Kubernetes cluster.

- `tools/vault/import.sh CLUSTERNAME`:
    Prepare a new cluster inside Vault by importing existing secrets from `inventory/.etc`.
    Conceptually, this setup is identical to the setup provided by `mkcluster-root.sh`.
    Please see [Migrating an existing cluster to Vault](#migrating-an-existing-cluster-to-vault) for details.

- `tools/vault/mkcluster-intermediate.sh CLUSTERNAME`:
    Prepare a new cluster inside Vault,
    with intermediate CAs only.
    This setup is not immediately usable,
    because the intermediate CAs first need to be signed with a root CA.
    Management of that root CA is out of scope for yaook/k8s;
    this script is intended to integrate with your own separate root CA infrastructure.
    The certificate sign requests are provided as `*.csr` files in the working directory.

- `tools/vault/load-signed-intermediates.sh CLUSTERNAME`:
    Load the signed intermediate CA files into the cluster.
    This script should only be used with clusters which have been bootstrapped using `mkcluster-intermediate.sh`, or equivalent.
    As input, this script expects `*.fullchain.pem` files in its current working directory,
    one for each `*.csr` file emitted by `mkcluster-intermediate.sh`.
    These files must contain two certificates:
    the signed intermediate certificate and, following that,
    the complete chain of trust up to the root CA, in this order.

- `tools/vault/dev-mkorchestrator.sh`:
    Creates an approle with the orchestrator policy.
    As this abuses the nodes approle auth plugin,
    this should not be used on productive clusters.
    In addition, every time this script is invoked,
    a new secret ID is generated
    without cleaning up the old one.
    This is generally fine for dev setups,
    but it's another reason not to run this against productive clusters.

- `tools/vault/rmcluster.sh CLUSTERNAME`:
    Deletes all data associated with the cluster from Vault.
    EXCEPTIONALLY DANGEROUS, so it always requires manual confirmation.

## Migrating an existing cluster to Vault

There are two choices to migrate your cluster to Vault:

- Root CA only
- With Intermediate CA

### Root CA only

In this mode, the existing root CA keys will be copied into Vault.
This is the simplest mode of operation,
but may not be compliant with your security requirements,
as the root CA keys are held "online" within Vault.

Conceptually, this mode is similar to running `mkcluster-root.sh` (see above).

To run a migration in this mode, call:

```console
$ managed-k8s/tools/import.sh $clustername no-intermediates
```

### With Intermediate CA

In this mode, a fresh intermediate CA key pair is created within Vault.
The root CA keys are *not* imported into Vault.
The import script generates Certificate Sign Requests
for each intermediate CA.
Before the cluster can be managed with Vault,
it is thus required to sign the CSRs
and load the signed certificates using
`load-signed-intermediates.sh`.

Conceptually, this mode is similar to running `mkcluster-intemediate.sh` (see above).

To start a migration in this mode, call:

```console
$ managed-k8s/tools/import.sh $clustername with-intermediates
```

This will print a message
indicating that the CSRs have been written
and to which files they have been written.

In addition,
like the `no-intermediates` mode,
this mode takes care that the root CA files are actually usable as CAs
(this is not ensured by the pre-vault LCM but somehow nothing cared).

You now must use the CA key and certificates stored in `inventory/`
to sign the respective CAs.
How you do this is out of scope for this document,
as it'll highly depend on your organizations security policy requirements.

Please see the documentation of `load-signed-intermediates.sh` above
for details on the files expected by that script
in order to load the signed certificates.

Once you have provided the files, run:

```console
$ managed-k8s/tools/load-signed-intermediates.sh $clustername
```

to load the signed intermediate CA certificates into Vault.

## Pivoting a cluster to host its own vault

"to pivot" means "to turn on an exact spot".
Here, we use this verb to mean that an existing cluster,
which is reliant on another Vault instance,
is changed such that relies on a Vault instance
running within that very same cluster.

### Motivation

As every yaook/k8s cluster needs a Vault instance
it uses as a root of trust and identity,
the question becomes where to host that Vault instance.
An obvious answer is to run it inside Kubernetes.
However, if you were to use yaook/k8s again,
where would *that* cluster have its root of trust?

The answer is pivoting.
When a cluster has no other Vault to rely on,
for instance because it is the root of trust in a site,
it becomes necessary that it hosts its own Vault.
Despite sounding nonsensical,
this is an expressly supported use-case.

### Prerequisites and Caveats

In order to migrate a cluster to host its own vault,
the following prerequisites are necessary:

- The cluster has been deployed or migrated to use another Vault.
  This can be the development Vault setup provided with yaook/k8s.

- The source Vault instance uses Raft.

- A sufficient amount of unseal key shares to unseal the *source* Vault
  are known.

- No Vault has been deployed with yaook/k8s inside the cluster yet.

**Note:** In general, it is not possible to pivot the cluster
except by restoring a Vault raft snapshot into the cluster.
This implies that *all* data from the source Vault
is imported into the cluster.
Thus, if you plan to pivot a cluster later,
make sure to use a fresh Vault instance
to avoid leaking data into the cluster you'd rather not have there.

**Note:** An exception to the above rule exists
if the cluster has been migrated and the original CA files still exist.
In that case, it can be migrated *again* into the Vault it hosts itself.
This process is left as an exercise to the reader.

### Procedure

In the following,
we will call the Vault instance
with which the cluster has been deployed the *source Vault*.
The Vault instance which we will spawn inside the cluster
will be called the *target Vault*.

1. Obtain the number of unseal shares and the threshold
   for unsealing of the *source Vault*.

2. Configure `k8s-service-layer.vault` with the same number of unseal shares
   and the same threshold.
   Enable the vault instance
   and configure any other options you might want to set,
   such as backup configuration.
   Set the `service_type` to `NodePort`
   and set the `active_node_port` to `32048`.

3. Deploy the Vault by re-running Stage 4.

4. Verify that you can reach the Vault instance
   by running `curl -k https://$nodeip:32048`,
   where you substitute `$nodeip`
   with the IP of any worker or control plane node.
   (You should get some HTML back.)

5. Take a raft snapshot of your *source Vault*
   by running `vault operator raft snapshot save foo.snap`
   with a sufficiently privileged token.

6. Obtain the CA of the *target Vault* from Kubernetes
   using `kubectl -n k8s-svc-vault get secret vault-cert-internal -o json | jq -r '.data["ca.crt"]' | base64 -d > vault-ca.crt`

7. Configure access to the Vault:
   ```
   export VAULT_ADDR=https://$nodeip:32048
   export VAULT_CACERT="$(pwd)/vault-ca.crt"
   unset VAULT_TOKEN
   ```

   Verify connectivity using:
   `vault status`.

   You should see something like:
   ```
   Key                     Value
   ---                     -----
   Seal Type               shamir
   Initialized             true
   Sealed                  false
   Total Shares            1
   Threshold               1
   Version                 1.12.1
   Build Date              2022-10-27T12:32:05Z
   Storage Type            raft
   Cluster Name            vault-cluster-4a491f8a
   Cluster ID              40dfd4ea-76ac-b2d0-bb9a-5a35c0a9bc9d
   HA Enabled              true
   HA Cluster              https://vault-0.vault-internal:8201
   HA Mode                 active
   Active Since            2023-03-01T18:42:41.824499649Z
   Raft Committed Index    44
   Raft Applied Index      44
   ```

   *Tip*: Verify that you're talking to the *target Vault*
   by checking the *Active Since* timestamp.

8. Obtain a root token for the *target Vault* instance.
   As you have just freshly installed it with yaook/k8s,
   the root token will be in `inventory/.etc/vault_root_token`.

9. Scale the vault down to one replica.

10. Delete the PVCs of the other replicas.

    **Note:** We are entering the danger zone now.
    Double-check always that you are operating on the correct cluster
    and with the correct vault.

11. **DANGER:** THIS WILL IRREVERSIBLY DELETE THE DATA IN THE *target Vault*.
   Double-check you are talking to the correct vault!
   Take a snapshot or whatever!

   Restore the snapshot from the *source Vault* in the *target Vault*.

   ```
   vault operator raft snapshot restore -force foo.snap
   ```

12. Manually unseal the *target Vault*:

    ```
    kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- vault operator unseal
    ```

    You now need to supply unseal key shares from the *source Vault*.

13. Force vault to reset whatever it thinks about the cluster state.
    This is done by triggering a Raft recovery
    by placing a magic `peers.json` file in the raft data directory.

    First, we need to find the node ID:

    ```
    kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- cat /vault/data/node-id; echo
    ```

    Then create the `peers.json` file:

    ```json
    [
      {
        "id": "...",
        "address": "vault-0.vault-internal:8201",
        "non_voter": false
      }
    ]
    ```

    (fill in the `id` field with the ID you found above)

    Upload the `peers.json` into the Vault node:

    ```
    kubectl -n k8s-svc-vault cp -c vault peers.json vault-0:/vault/data/raft/
    ```

    Restart the Vault node:

    ```
    kubectl -n k8s-svc-vault delete pod vault-0
    ```

    Once it comes up, unseal it again:

    ```
    kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- vault operator unseal
    ```

    This should now show the `HA Mode` as active.

14. Scale the cluster back up.

    ```
    kubectl -n k8s-svc-vault scale sts vault --replicas=3
    ```

15. Unseal the other replicas:

    ```
    kubectl -n k8s-svc-vault exec -it vault-1 -c vault -- vault operator unseal
    kubectl -n k8s-svc-vault exec -it vault-2 -c vault -- vault operator unseal
    ```

    Congrats! You now have the data inside the k8s cluster.

16. To test that yaook/k8s can talk to the Vault appropriately,
    you can now run any stage3 with `AFLAGS="-t vault-onboarded"`
    to see if it can talk to Vault.
