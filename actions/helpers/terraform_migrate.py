#!/usr/bin/env python3

import argparse
from functools import reduce
from inspect import signature
import json
import logging
from os import environ as env
from pathlib import Path
import subprocess
import toml

import novaclient.client  # from python-openstackclient package
import novaclient.exceptions
import neutronclient.v2_0.client  # from python-neutronclient package
import neutronclient.common.exceptions
import keystoneauth1.identity  # dependency of python-neutronclient package
import keystoneauth1.session  # dependency of python-neutronclient package


CODE_FAILURE = 1
CODE_SUCCESS = 0

logging.basicConfig(
    format='%(levelname)s: %(message)s',
    level=logging.INFO,
)

# tasks registry
TASKS = {}

# Mapping between Terraform and Openstack resource types
tf_os_resource_type_map = {
    "openstack_networking_port_v2": "port",
    "openstack_compute_instance_v2": "server",
}


class OpenstackResourceNotFound(Exception):
    def __init__(self, message):
        self.message = message


def register_task(name: str, order: int = 100) -> None:
    """Decorator for registering migration tasks

    Args:
        name: Name to register the task under
        order: Queue seat for the task (lowest is first)
    """
    def decorator(fn):
        TASKS[name] = {
            "callable": fn,
            "params": list(signature(fn).parameters.keys()),
            "order": order,
            # NOTE: implementing after/before dependencies instead
            #       would require toposort
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


class OpenstackClient():
    """Openstack client interface"""
    def __init__(self):
        self.credentials = self._get_credentials()
        self._init_clients(self.credentials)

    def _get_credentials(self) -> dict:
        return {
            "auth_url": env['OS_AUTH_URL'],
            # "endpoint_type": env['OS_INTERFACE'],
            # "region_name": env['OS_REGION_NAME'],
            "project_domain_name": env['OS_PROJECT_DOMAIN_ID'],
            "project_name": env['OS_PROJECT_NAME'],
            "user_domain_name": env['OS_USER_DOMAIN_NAME'],
            "username": env['OS_USERNAME'],
            "password": env['OS_PASSWORD'],
        }

    def _init_clients(self, credentials: dict) -> None:
        self.compute_client = novaclient.client.Client(
            version=2,  # Compute API version
            **credentials
        )
        self.network_client = neutronclient.v2_0.client.Client(
            session=keystoneauth1.session.Session(
                auth=keystoneauth1.identity.Password(
                    **credentials
                )
            )
        )

    def rename_resource(self, ref: tuple, new_name: str) -> str:
        """Rename an Openstack resource by type and UUID"""
        type_, uuid = ref
        if type_ == "port":
            try:
                self.rename_port(uuid=uuid, new_name=new_name)
            except OpenstackResourceNotFound:
                return "not-found"
            return "success"
        elif type_ == "server":
            try:
                self.rename_server(uuid=uuid, new_name=new_name)
            except OpenstackResourceNotFound:
                return "not-found"
            return "success"
        else:
            raise ValueError(f"Resource type {type_} is not supported.")

    def rename_server(self, uuid: str, new_name: str):
        """Rename an Openstack server by UUID"""
        try:
            self.compute_client.servers.update(server=uuid, name=new_name)
        except novaclient.exceptions.NotFound as e:
            raise OpenstackResourceNotFound(message=e.message)

    def rename_port(self, uuid: str, new_name: str):
        """Rename an Openstack port by UUID"""
        try:
            self.network_client.update_port(
                port=uuid,
                body={"port": {"name": new_name}}
            )
            # NOTE: Openstack Network API reference at
            #       https://docs.openstack.org/api-ref/network/v2/index.html#update-port
        except neutronclient.common.exceptions.PortNotFoundClient as e:
            raise OpenstackResourceNotFound(message=e.message) from e


def get_tf_var_defaults() -> dict:
    """Return default values of YAOOK/k8s Terraform variables"""

    # Defaults taken from the YAOOK/k8s Terraform module
    return {
        "azs": ["AZ1", "AZ2", "AZ3"],
        "cluster_name": "managed-k8s",
        "create_root_disk_on_volume": False,
    }


@register_task(name="count-to-for_each", order=1)
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


@register_task(name="index-based-gateway-names", order=2)
def rename_gateways_index_based(
        tf_mod_dir: str, config: dict, dry_run: bool = False
) -> int:
    f"""Rename gateway nodes and related resources to index based scheme

    Args:
        tf_mod_dir: The path of the YAOOK/k8s Terraform directory
        config: A parsed YAOOK/k8s configuration
        dry_run: Do not apply changes if set to true

    Returns:
        {CODE_SUCCESS} for success, {CODE_FAILURE} for failure
    """
    outcome = CODE_SUCCESS

    terraform = TerraformCLI(tf_mod_dir=tf_mod_dir)
    openstack = OpenstackClient()

    tf_var_defaults = get_tf_var_defaults()

    _tf_addr_mappings = []
    # format: [(<old_terraform_address>, <new_terraform_address>)]
    _os_name_mappings = []
    # format: [((<resource_type>, <openstack_uuid>), <new_openstack_name>)]

    azs = config["terraform"].get("azs", tf_var_defaults["azs"])
    cluster_name = config["terraform"].get(
        "cluster_name", tf_var_defaults["cluster_name"]
    )
    create_root_disk_on_volume = config["terraform"].get(
        "create_root_disk_on_volume",
        tf_var_defaults["create_root_disk_on_volume"]
    )

    # Create mappings between the old and new config maps
    #  that the yk8s Terraform module produces for the gateway nodes
    _tf_cfg_mappings = []
    for idx, az in enumerate(azs):
        _tf_cfg_mappings.append(
            (
                {
                    "_key": f"{cluster_name}-gw-{az.lower()}",
                    "volume_name": f"{cluster_name}-gw-volume-{az.lower()}"
                },
                {
                    "_key": f"{cluster_name}-gw-{idx}",
                    "volume_name": f"{cluster_name}-gw-{idx}-volume"
                }
            )
        )

    # Get Terraform resources from state
    try:
        tf_resources = \
            terraform.state_show_json()["values"]["root_module"]["resources"]
    except KeyError:
        logging.info("No resources in Terraform state.")
        return outcome

    # Process all applicable Terraform resources
    for (tf_resource_type, tf_resource_name, tf_resource_index,
            skip, rename_in_os) in [
        ("openstack_networking_port_v2", "gateway", "_key",
            False, True),
        ("openstack_blockstorage_volume_v3", "gateway-volume", "volume_name",
            (not create_root_disk_on_volume), False),
        ("openstack_compute_instance_v2", "gateway", "_key",
            False, True),
        ("openstack_networking_floatingip_v2", "gateway", "_key",
            False, False),
        ("openstack_compute_floatingip_associate_v2", "gateway", "_key",
            False, False),
    ]:
        if skip:
            continue

        # Retrieve candidates for renaming from Terraform state
        tf_targets = {
            x["index"]: x  # NOTE: index is representative of the whole address
            for x in tf_resources
            if (
               x["type"] == tf_resource_type
               and x["name"] == tf_resource_name
            )
        }

        # Sanity check the amount of candidates
        if len(tf_targets) != len(azs):
            logging.warning(
                "Mismatch between the amount of azs and the amount of actual"
                f" {tf_resource_type}.{tf_resource_name} resources:"
                f" azs=[{', '.join(azs)}]"
                f" gateways=[{', '.join(tf_targets)}]"
            )

        # Calculate mappings
        for tf_cfg_mapping in _tf_cfg_mappings:
            old_name = tf_cfg_mapping[0][tf_resource_index]
            new_name = tf_cfg_mapping[1][tf_resource_index]

            # Generate Terraform resource mappings
            #  for existing outdated resources
            if old_name in tf_targets:
                # target must still be renamed in Terraform
                tf_target = tf_targets[old_name]
                old_tf_address, new_tf_address = (
                    tf_target["address"],
                    f'{tf_target["type"]}.{tf_target["name"]}["{new_name}"]'
                )
                _tf_addr_mappings.append(
                    (old_tf_address, new_tf_address)
                )
            elif new_name in tf_targets:
                # target was already renamed in Terraform
                tf_target = tf_targets[new_name]
                pass
            else:
                # target should exist in the Terraform state but does not
                # warn and skip
                old_tf_address, new_tf_address = (
                    f'{tf_resource_type}.{tf_resource_name}["{old_name}"]',
                    f'{tf_resource_type}.{tf_resource_name}["{new_name}"]'
                )
                logging.warning(
                    f"Missing resource in Terraform state:"
                    f" expected_address={old_tf_address} or {new_tf_address}"
                )
                continue

            if not rename_in_os:
                continue  # skip

            # Generate Openstack resource mappings
            #  for existing outdated resources (as per Terraform state)
            os_resource_name = tf_target["values"]["name"]
            os_resource_id = tf_target["values"]["id"]
            if os_resource_id is not None and os_resource_name != new_name:
                # target must be renamed in Openstack
                os_resource_type = tf_os_resource_type_map[tf_resource_type]
                _os_name_mappings.append(
                    ((os_resource_type, os_resource_id), new_name)
                )

    # Perform the collected renames
    for backend, handler, mappings in [
        ("Openstack", openstack.rename_resource, _os_name_mappings),
        ("Terraform", terraform.state_mv, _tf_addr_mappings),
    ]:
        if len(mappings) != 0:
            logging.info(
                f"{'Would rename' if dry_run else 'Renaming'}"
                f" the following resources in {backend}:"
            )
            for old, new in mappings:
                if not dry_run:
                    _outcome = handler(old, new)
                else:
                    _outcome = "dry-run"

                if _outcome == "fail":
                    outcome = CODE_FAILURE

                logging.info(
                    f"* ({_outcome:9})"
                    f" {' '.join(old) if isinstance(old, tuple) else old}"
                    f" --> {new}"
                )
        else:
            logging.info(f"Nothing to do in {backend}.")

    return outcome


def get_args() -> argparse.Namespace:
    """Parse command line arguments and return them"""

    # Pre-parse --tasks argument
    # so that we can require further arguments based on the selected tasks
    pre_parser = argparse.ArgumentParser(add_help=False)
    pre_parser.add_argument(
        '--tasks', type=str, nargs='*', default=list(TASKS.keys())
    )
    pre_args = pre_parser.parse_known_args()

    help_arg_given = any(x in pre_args[1] for x in ["-h", "--help"])
    config_arg_required = (
        "config" in reduce(
            lambda a, b: a+b,
            [
                TASKS.get(task, {}).get("params", [])
                for task in pre_args[0].tasks
            ], []
        )
    )

    parser = argparse.ArgumentParser(
        description=(
            "Perform migration tasks in Terraform"
            " required by the current release"
        ),
        epilog=(
            "This script may connect to Openstack."
            " Make sure to provide the following environment variables:"
            " OS_AUTH_URL, OS_INTERFACE, OS_REGION_NAME"
            " ,OS_PROJECT_DOMAIN_ID, OS_PROJECT_NAME"
            " ,OS_USER_DOMAIN_NAME, OS_USERNAME, OS_PASSWORD"
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
        help="Specific task(s) to perform. Default is all tasks.",
    )
    if config_arg_required or help_arg_given:
        _tasks_need_config_arg = [
            task for task, spec in TASKS.items() if "config" in spec["params"]
        ]
        parser.add_argument(
            '--config-file', type=argparse.FileType('r'),
            required=True,
            help=(
                "The path to a YAOOK/k8s config file in the old format."
                " (only required for certain tasks:"
                f" {', '.join(_tasks_need_config_arg)})"
            ),
        )
    parser.add_argument(
        '--tf-gitlab-backend', type=str,
        help="The address of the Gitlab Terraform backend (optional)"
    )
    parser.add_argument(
        'tf_mod_dir', type=Path,
        help="The path to the YAOOK/k8s Terraform module",
    )

    args = parser.parse_args()

    return args


def run_tasks(tasks: list, args: dict) -> int:
    f"""Execute the given tasks in the correct order with the right args

    Args:
        tasks: A list of task names
        args: A set of key-value-arguments to satisfy the given tasks

    Returns:
        {CODE_SUCCESS} for success of all tasks,
        {CODE_FAILURE} for failure of at least one task
    """
    tasks.sort(key=lambda task: TASKS[task]["order"])

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

    # Read config
    if args.get("config_file", None) is not None:
        args["config"] = toml.loads(args["config_file"].read())
        args["config_file"].close()

    # Execute all tasks that were selected
    outcome = run_tasks(args.pop("tasks"), args)

    exit(outcome)
