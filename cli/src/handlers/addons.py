import subprocess
import tempfile
from pathlib import Path

import ansible_runner
import yaml

import handlers.config


def apply(cluster_repo, code_path):
    handlers.config.update_inventory(cluster_repo, code_path, "addons")

    inventory = cluster_repo / "inventory/addons"
    with (inventory / "main.yaml").open("r") as f:
        addons = yaml.safe_load(f)

    # TODO: Build DAG

    for name, addon in addons.items():
        if addon["type"] == "playbook":
            apply_playbook(inventory / name, addon)
        elif addon["type"] == "command":
            apply_command(addon)
        else:
            raise ValueError(f"Invalid addon type {addon["type"]}")


def apply_playbook(inventory: Path, addon: dict):
    print(f"Running playbook addon at {addon["path"]}")
    with tempfile.TemporaryDirectory() as data_dir:
        r = ansible_runner.run(
            private_data_dir=data_dir,
            roles_path=addon["playbook"]["role_paths"],
            playbook=addon["path"],
            inventory=str(inventory.resolve() / "hosts"),
        )
    print("{}: {}".format(r.status, r.rc))
    # for each_host_event in r.events:
    #     print(each_host_event["event"])
    # print("Final status:")
    # print(r.stats)


def apply_command(addon: dict):
    print(f"Running command addon at {addon["path"]}")
    subprocess.run(addon["path"])
