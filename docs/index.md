---
hide-doc: true
---

# Welcome to TAROOK's documentation!

```{eval-rst}
.. toctree::
    :hidden:

    introduction

.. toctree::
    :hidden:

    Releases <https://meta.docs.tarook.cloud/supported_releases.html>
    releasenotes

.. toctree::
    :hidden:
    :caption: User Documentation

    user/explanation/index
    user/guide/index
    user/reference/index

.. toctree::
    :hidden:
    :caption: Developer Documentation

    developer/explanation/index
    developer/guide/index
    developer/reference/index

```

::::{grid} 1
:::{grid-item-card}
:link: /introduction
:link-type: doc
**Tarook** is a holistic life-cycle management tool based on Ansible, Nix, and Terraform, designed to deploy a flexible, customizable, highly available, and scalable kubeadm-based Kubernetes distribution — on OpenStack, Proxmox and bare-metal infrastructures.
:::
::::


::::{grid} 1
:::{grid-item-card}  Quick Start Guide
:link: /user/guide/quick-start/index
:link-type: doc
The quick start guide is meant to give you a kickstart in deploying your first Tarook cluster.
:::
::::

::::{grid} 2
:::{grid-item-card}  Releasenotes
:link: releasenotes
:link-type: doc
The releasenotes give you all essential information about recent changes.
:::
:::{grid-item-card} Release upgrade
:link: /user/guide/upgrade-release
:link-type: doc
Guide on how to upgrade to a new TAROOK release.
:::
::::

---

::::{grid} 3
:::{grid-item-card}  User Explanations
:link: /user/explanation/index
:link-type: doc
In-depth explanations and discussion about how (and why) Tarook works from the user perspective.
:::
:::{grid-item-card}  User Guide
:link: /user/guide/index
:link-type: doc
Keep this under your pillow when *running* Tarook clusters.
:::
:::{grid-item-card}  User References
:link: /user/reference/index
:link-type: doc
Technical reference documentation of TAROOK from the user perspective.
:::
::::

---

::::{grid} 3
:::{grid-item-card}  Developer Explanations
:link: /developer/explanation/index
:link-type: doc
In-depth explanations and discussion about how (and why) Tarook works from the developer perspective.
:::
:::{grid-item-card}  Developer Guides
:link: /developer/guide/index
:link-type: doc
Keep this at hand when *developing* with Tarook.
:::
:::{grid-item-card}  Developer References
:link: /developer/reference/index
:link-type: doc
Technical reference documentation of Tarook from the developer perspective.
:::
::::
