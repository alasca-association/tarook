import subprocess


def update_inventory(cluster_repo, code_path, target):
    subprocess.run(
        [code_path / "actions/update-inventory.sh", target],
        cwd=cluster_repo,
    )
