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

## Managing Clusters in Vault

The following scripts are provided in order to manage a Vault instance for yaook/k8s:

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
