#!/usr/bin/env python3

import argparse
from inspect import signature
import json
import logging
from pathlib import Path
import subprocess


CODE_FAILURE = 1
CODE_SUCCESS = 0

logging.basicConfig(
    format='%(levelname)s: %(message)s',
    level=logging.INFO,
)

# tasks registry
TASKS = {}


def register_task(name: str) -> None:
    """Decorator for registering migration tasks

    Args:
        name: Name to register the task under
    """
    def decorator(fn):
        TASKS[name] = {
            "callable": fn,
            "params": list(signature(fn).parameters.keys()),
        }
        return fn
    return decorator


def run_shell_cmd(*args, input: str = None) -> dict:
    """Execute a shell command

    Args:
        *args: Command line arguments
        input: Optional input to pass to the command

    Returns:
        A dictionary with the command's exit code (ec)
         and utf-8 decoded stdout (out) and stderr (err).
    """
    proc = subprocess.run(
        *args,
        input=(input.encode('utf-8') if input is not None else None),
        check=False,
        capture_output=True,
    )
    return {
        "ec": proc.returncode,
        "out": proc.stdout.decode('utf-8'),
        "err": proc.stderr.decode('utf-8')
    }


class TerraformCLI():
    """Terraform command line client interface"""
    def __init__(
        self,
        cmd: str = "terraform",
        tf_mod_dir: Path = Path("."),
        tf_backend_address: str = None,
    ):
        self.backend_address = (
            tf_backend_address
            or globals().get("TF_BACKEND_ADDRESS", None)
        )

        self.cmd = cmd
        self.tf_mod_dir = Path(tf_mod_dir)

        self.base_cmd = [cmd, f"-chdir={tf_mod_dir}"]

        self.init(backend_address=self.backend_address)

    def init(self, backend_address: None) -> None:
        """Initialize Terraform"""
        cmd_line = \
            self.base_cmd + ["init"]

        if backend_address is not None:
            cmd_line.extend([
                f"-backend-config='address={backend_address}'",
                f"-backend-config='lock_address={backend_address}/lock'",
                f"-backend-config='unlock_address={backend_address}/lock'",
                "-backend-config='lock_method=POST'",
                "-backend-config='unlock_method=DELETE'",
                "-backend-config='retry_wait_min=5'",
            ])

        r = run_shell_cmd(cmd_line)

        if r["ec"] != 0:
            raise RuntimeError(
                f"Failed to initialize Terraform: {' '.join(cmd_line)}"
            )

    def state_show_json(self) -> dict:
        """Return the current Terraform state as JSON"""
        cmd_line = \
            self.base_cmd + ["show", "-json"]
        r = run_shell_cmd(cmd_line)

        if r["ec"] != 0:
            raise RuntimeError(
                f"Failed to read Terraform state: {' '.join(cmd_line)}"
            )

        return json.loads(r["out"])

    def state_mv(self, src_addr: str, dest_addr: str) -> str:
        """Move an address in the Terraform state"""
        cmd_line = \
            self.base_cmd + ["state", "mv", src_addr, dest_addr]
        r = run_shell_cmd(cmd_line)

        return "success" if r["ec"] == 0 else "fail"


@register_task(name="count-to-for_each")
def migrate_count_to_for_each(tf_mod_dir: str, dry_run: bool = False) -> int:
    f"""Migrate resources from ``count`` to ``for_each`` in the Terraform state

    Args:
        tf_mod_dir: The path of the YAOOK/k8s Terraform directory
        dry_run: Do not apply changes if set to true

    Returns:
        {CODE_SUCCESS} for success, {CODE_FAILURE} for failure
    """
    outcome = CODE_SUCCESS

    _tf_addr_mappings = {}  # <old_address>: <new_address>

    terraform = TerraformCLI(tf_mod_dir=tf_mod_dir)

    # Retrieve migration candidates from Terraform state
    # We target the following resources:
    # - master nodes and their volume
    # - worker nodes and their volume
    # - gateway nodes and their volume
    try:
        tf_resources = \
            terraform.state_show_json()["values"]["root_module"]["resources"]
    except KeyError:
        logging.info("No resources in Terraform state.")
        return outcome

    tf_targets = [
        x for x in tf_resources
        if (
            (
                x["type"] == "openstack_compute_instance_v2"
                and x["name"] in ["master", "worker", "gateway"]
            ) or (
                x["type"] == "openstack_blockstorage_volume_v3"
                and x["name"] in ["master-volume", "worker-volume", "gateway-volume"]
            )
        ) and isinstance(x["index"], int)
        # NOTE: An integer index indicates the use of Terraform `count`
    ]

    # Calculate mappings
    for tf_target in tf_targets:
        _tf_addr_mappings[tf_target["address"]] = \
            f'{tf_target["type"]}.{tf_target["name"]}' \
            f'["{tf_target["values"]["name"]}"]'

    # Rename
    if len(_tf_addr_mappings) != 0:
        logging.info(
            f"{'Would rename' if dry_run else 'Renaming'}"
            f" the following resources in Terraform:"
        )
        for old, new in _tf_addr_mappings:
            if not dry_run:
                _outcome = terraform.state_mv(old, new)
            else:
                _outcome = "dry-run"

            if _outcome == "fail":
                outcome = CODE_FAILURE

            logging.info(f"* ({_outcome:7}) {old} --> {new}")
    else:
        logging.info("Nothing to do.")

    return outcome


def get_args() -> argparse.Namespace:
    """Parse command line arguments and return them"""
    parser = argparse.ArgumentParser(
        description=(
            "Perform migration tasks in Terraform"
            " required by the current release"
        ),
    )
    parser.add_argument(
        '--dry-run', action='store_true',
        default=False,
        help="Do not perform disruptive actions"
    )
    parser.add_argument(
        '--tasks', type=str, nargs='*',
        choices=list(TASKS.keys()),
        default=list(TASKS.keys()),
        help="Specific task(s) to perform. Default is all tasks.)",
    )
    parser.add_argument(
        '--tf-gitlab-backend', type=str,
        help="The address of the Gitlab Terraform backend (optional)"
    )
    parser.add_argument(
        'tf_mod_dir', type=Path,
        help="The path to the YAOOK/k8s Terraform module",
    )

    return parser.parse_args()


def run_tasks(tasks: list, args: dict) -> int:
    f"""Execute the given tasks with the right args

    Args:
        tasks: A list of task names
        args: A set of key-value-arguments to satisfy the given tasks

    Returns:
        {CODE_SUCCESS} for success of all tasks,
        {CODE_FAILURE} for failure of at least one task
    """
    outcome = CODE_SUCCESS

    for task in tasks:
        logging.info(f"Running task: {task}")
        _outcome = TASKS[task]["callable"](
            **{
                param: val for param, val in args.items()
                if param in TASKS[task]["params"]
            }
        )

        if _outcome != CODE_SUCCESS:
            outcome = CODE_FAILURE

    return outcome


if __name__ == "__main__":
    args = vars(get_args())

    # NOTE: Modifies the default TerraformCLI class
    TF_BACKEND_ADDRESS = args.get("tf_gitlab_backend", None)

    # Execute all tasks that were selected
    outcome = run_tasks(args.pop("tasks"), args)

    exit(outcome)
