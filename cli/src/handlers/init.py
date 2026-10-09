import os

from lib import exec_cmd


def dispatch(cluster_repo, branch, extra_args):

    submodule_managed_k8s_url = os.environ.get(
        "MANAGED_K8S_GIT", "https://gitlab.com/alasca.cloud/tarook/tarook.git"
    )

    if branch is None:
        raise NotImplementedError
        # branch = # TODO get version

    url = f"git+{submodule_managed_k8s_url}?ref={branch}"

    exec_cmd(
        cluster_repo,
        "nix",
        [
            "run",
            f"{url}#init",
            "--",
        ]
        + extra_args,
    )
