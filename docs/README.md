# TAROOK Handbook

This documentation is generated using sphinx.

## Table of Contents

See [index.md](index.md).

Build the documentation by running the below from the repository's root.

```shell
# Build documentation
nix build .#docs

# Open in Firefox
firefox result/index.html
```

The output path can be adjusted via `--out-link path/to/docs`.

You can even watch for file changes and instantly see modifications for changes to the documentation by running:

```shell
# Build and watch the documentation for changes
nix develop .#docs-dev
# Open in browser
firefox http://127.0.0.1:8000
```

In case you want to build the documentation on non-supported system architectures you can run for example to build the
docs on macOS. More information can be found [here](https://github.com/nix-systems/nix-systems).

```shell
nix build --override-input systems github:nix-systems/aarch64-darwin .#docs
```
