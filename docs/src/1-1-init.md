# Initialization

## Prepare your direnv

Even though not a hard requirement it's strongly recommended to use direnv to
properly setup your environment varibles.
Check the top of [Environment variables](#environment-variables)

## Empty git repository

To start out with a cluster, you need an (empty) git repository which will
serve as your cluster repository:

```console
$ git init my-test-cluster
$ cd my-test-cluster
```

## Initialise cluster repository

To create the initial bare-minimum directory structure, a script is provided
in the `managed-k8s` project.

Clone the `managed-k8s` repository to a location **outside** of your cluster
repository:

```console
$ pushd "$somewhere_else"
$ git clone git@gitlab.cloudandheat.com:lcm/managed-k8s
$ popd
```

Now you can run ``init.sh`` to bootstrap your cluster repository. Back in your
cluster repository directory, you now call the `init.sh` script from the
`managed-k8s` repositor you just cloned:

```console
$ "$somewhere_else/actions/init.sh"
```

The `init.sh` script will:

- Add all necessary submodules
- Copy a config.toml template if no config exists in the cluster repository yet
- Update the .gitignore to current standards

- create the dir env, check the top of
  [Environment variables](#environment-variables)
