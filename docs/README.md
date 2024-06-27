# Yaook/k8s Handbook

This documentation is generated using sphinx.

## Table of Contents

See [index.rst](index.rst).

## How to render

Install sphinx by executing:

```shell
# Install dependencies via poetry
poetry install --with docs --sync
```

To build the documentation use:

```shell
# Build documentation
nix run .#renderDocs

# Open in Firefox
firefox _build/html/index.html
```
