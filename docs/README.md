# YAOOK/K8s Handbook

This documentation is generated using sphinx.

## Table of Contents

See [index.rst](index.rst).

## How to render

It is required that the docs package group is available in the environment, eg. by setting

```shell
export YAOOK_K8S_DEVSHELL="dev"
```

in `.envrc.local`.

To build the documentation use, in the root directory:

```shell
# Build documentation
nix run .#renderDocs

# Open in Firefox
firefox _build/html/index.html
```
