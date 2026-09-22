SBOM
====

Tarook provides an Build Software Bill of Material (Build SBOM), which uses the
CycloneDX format. That means the SBOM is been generated in the build process of
a new realease.

Captured dependencies
---------------------

There are currently three main dependency categories captured:

Nix dependencies
~~~~~~~~~~~~~~~~

These are tracked by the `bombon
<https://github.com/nikstur/bombon>`__
tool.

The scope of the Nix packages are collected from the ``dev`` and ``ci`` Nix environment.

Container Images
~~~~~~~~~~~~~~~~

The dependencies of images used in the CI. The dependencies of
these images are captured via `syft
<https://github.com/anchore/syft>`__.

Runtime dependencies
~~~~~~~~~~~~~~~~~~~~

This includes Ansible galaxy collections and Helm Charts. These are collected by
python script.

Depth of the SBOM
-----------------

As for now we are collecting only direct dependencies for the nix and runtime stages.

In the container stage alle dependencies, so also all transitive dependencies.
This is caused by the limitation of ``syft``, as the `dependency depth can't by controlled <https://github.com/anchore/syft/issues/3968>`__.
