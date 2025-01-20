How to Upgrade YAOOK/K8s Cluster
================================

In this tutorial, we will guide you step-by-step through the process of upgrading YAOOK/K8s clusters.

The process is divided into different key sections:

Prerequisites
-------------
Before starting, ensure you have the following:

- Access to the YAOOK/K8s cluster's repository.
- Each YAOOK/K8s cluster is maintained in its own dedicated cluster repository.
- Basic understanding of Git workflows.

1. Cloning a Cluster Repository
-------------------------------

If you are accessing the cluster repository for the first time, follow these steps to clone it.

Clone the Repository:
Use the following command to clone the repository to your local environment, including of all dependent submodules.

.. code:: console

    $ git clone --recursive <repository-url>

    $ less .envrc    # review for harmful code before allowing

    $ direnv allow

.. note::
    Replace <repository-url> with the specific URL of the YAOOK/K8s cluster repository and
    ensure you have the necessary permissions to access the repository.

2. Pulling Updates from a Cluster Repository
--------------------------------------------

If you already have a local copy of the repository, update it with the latest remote changes.

Navigate to the Cluster Repository and move into the repository directory:

.. code:: console

    $ cd <repository-folder>

Pull the Latest Changes:
Use the following command to synchronize your local copy with the remote repository:

.. code:: console

    $ git pull
    $ git submodule update --init --recursive

3. Handling YAOOK/K8s Versions
------------------------------

When using the LCM tool YAOOK/K8s, updates and upgrades follow the semantic versioning system (major, minor and patch).
However, it is recommended to consult the release notes in any case.

Patch Versions:
Skipping patch versions is generally safe because they typically contain backward-compatible fixes and improvements.

Minor Versions:
Skipping minor versions is usually supported, but it’s essential to carefully review the release notes.
Some features or improvements may require some steps or configuration adjustments.

Major Versions:
Skipping major versions is not supported and may introduce breaking changes that require significant manual intervention or adjustments to your configuration.

The guidelines for updateing between versions are as follows:

LCM update in YAOOK/K8s is feasible to the latest patch version (for example from 8.1.1 to 8.1.7).

LCM update in YAOOK/K8s is possible to the next minor version (for example from 8.1.x to 8.2.x).

LCM upgrade in YAOOK/K8s is only possible to the next major version (for example from 8.1 to 9.0).
If you want to upgrade from 7.1.x to 9.0.x for example, you must first upgrade to the intermediate major version (7.1 > 8.0 > 9.0)

For releases notes from YAOOK/K8s we will give an advanced using the
`changelog <https://yaook.gitlab.io/k8s/devel/releasenotes.html>`__.

Update the YAOOK/K8s submodule to the latest available patch version:

.. code:: console

    $ git submodule update --remote managed-k8s

Update the YAOOK/K8s submodule to a specific major and minor version:

.. code:: console

    $ git submodule set-branch --branch release/v8.1 managed-k8s
    $ git submodule update --remote

Verify the status of submodules by running the following command:

.. code:: console

    $ git submodule

4. Performing the Upgrade on the Cluster
----------------------------------------
Establish the WireGuard connection on non-baremetal systems:

.. code:: console

    $ managed-k8s/actions/wg-up.sh

Run the YAOOK/K8s Lifecycle Manager (LCM):

.. code:: console

    $ managed-k8s/actions/apply-all.sh

.. note::
    Generally, a single run of the LCM ensures all components are updated properly.

Verify the upgrade:
Confirm that the Kubernetes cluster is functioning as expected after the upgrade.

.. code:: console

    $ managed-k8s/actions/test.sh

    $ kubectl get nodes -o wide
    $ kubectl get pods -A | grep -Ev "Running|Completed"
