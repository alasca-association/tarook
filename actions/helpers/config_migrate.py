#!/usr/bin/env python3

import argparse
from copy import deepcopy
import json
import logging
from sys import stdin as sys_stdin

import tomlkit as toml


logging.basicConfig(
    format='%(levelname)s: %(message)s',
    level=logging.INFO,
)


def listget(list_: list, index: int, default):
    """Return a list value by index or the default if it does not exist"""
    try:
        return list_[index]
    except IndexError:
        return default


def get_tf_var_defaults() -> dict:
    """Return the defaults of YAOOK/k8s Terraform variables"""

    # Defaults taken from the terraform module
    return {
        "masters": 3,
        "workers": 4,
        "cluster_name": "managed-k8s",
        "enable_az_management": True,
    }


def convert_config_into_new_format(config: dict) -> dict:
    """Convert a YAOOK/k8s configuration into the new format

    Steps:
        1. Converts the ``[terraform]`` config section (idempotent)

           Builds a dict object for every node that gathers each node's
           attributes from the previously used attribute lists, if present.

    Args:
        config: A parsed YAOOK/k8s configuration

    Return:
        A copy of the given ``config`` converted into the new format
    """

    def convert_terraform_section(old_cfg: dict) -> dict:
        """Convert a Terraform YAOOK/k8s configuration into the new format

        Args:
            old_cfg: The Terraform section of a parsed YAOOK/k8s config

        Returns:
            A copy of the given ``old_cfg`` converted into the new format
        """
        new_cfg = deepcopy(old_cfg)

        # Skip if the config is already in the new format
        # NOTE: `[terraform].masters|workers` changed to
        #       `[terraform.masters|workers]`
        #       so we are simply using that as an indicator
        if isinstance(old_cfg.get("masters"), dict) \
           or isinstance(old_cfg.get("workers"), dict):
            return new_cfg

        tf_var_defaults = get_tf_var_defaults()

        # Mapping of new config keys to old config keys
        node_cfg_map = {
            "masters": {  # node group
                "count": "masters",       # node count
                "name":  "master_names",  # primary attribute
                "attrs": {                # attributes
                    # new attribute           : old attributes list
                    "image"                   : "master_images"                  ,  # noqa: E203, E501
                    "flavor"                  : "master_flavors"                 ,  # noqa: E203, E501
                    "az"                      : "master_azs"                     ,  # noqa: E203, E501
                    "root_disk_size"          : "master_root_disk_sizes"         ,  # noqa: E203, E501
                    "root_disk_volume_type"   : "master_root_disk_volume_types"  ,  # noqa: E203, E501
                },
            },
            "workers": {  # node group
                "count": "workers",       # node count
                "name":  "worker_names",  # primary attribute
                "attrs": {                # attributes
                    # new attribute           : old attributes list
                    "image"                   : "worker_images"                  ,  # noqa: E203, E501
                    "flavor"                  : "worker_flavors"                 ,  # noqa: E203, E501
                    "az"                      : "worker_azs"                     ,  # noqa: E203, E501
                    "root_disk_size"          : "worker_root_disk_sizes"         ,  # noqa: E203, E501
                    "root_disk_volume_type"   : "worker_root_disk_volume_types"  ,  # noqa: E203, E501
                    "join_anti_affinity_group": "worker_join_anti_affinity_group",  # noqa: E203, E501
                },
            },
        }

        def convert_node_group(grp):
            """Convert a single group of nodes, e.g. masters, workers"""
            return {
                name: {  # node name
                    # map old list-item-attribute to new attribute
                    new_attr: old_cfg[old_attr][idx]
                    # check all attributes
                    for new_attr, old_attr in node_cfg_map[grp]["attrs"].items()
                    # only create new attribute if old one existed
                    if idx < len(old_cfg.get(old_attr, []))
                }
                # iterate over all nodes as per count
                for idx, name in
                enumerate(  # create mapping of node index and name
                    # get list of node names
                    # default to node index for missing node names
                    listget(old_cfg.get(node_cfg_map[grp]["name"], []), i, str(i))
                    for i in range(
                        old_cfg.get(
                            node_cfg_map[grp]["count"], tf_var_defaults[grp]
                        )
                    )
                )
            }

        # Generate new config from old one
        _new_cfg = {
            grp: convert_node_group(grp) for grp in ["masters", "workers"]
        }

        # Clear old config keys
        for grp, keys in node_cfg_map.items():
            new_cfg.pop(keys["count"], None)
            new_cfg.pop(keys["name"], None)
            for _, old_attr in keys["attrs"].items():
                new_cfg.pop(old_attr, None)

        # Add new config keys
        new_cfg.update(_new_cfg)

        return new_cfg

    new_config = deepcopy(config)
    new_config["terraform"] = convert_terraform_section(
        deepcopy(config["terraform"])
    )
    return new_config


def sync_node_azs_in_tf_and_config(new_config: dict, tf_state: dict) -> dict:
    """Sync each node's availability zone in Terraform with the config

    Determines the current availability zone of each master and worker node
     from the Terraform state and sets it to that one in the configuration.

    Args:
        new_config: A parsed YAOOK/k8s configuration in the new format
                    (as produced by ``convert_config_into_new_format()``)
        tf_state: A YAOOK/k8s Terraform state in JSON format

    Returns:
        A copy of the given config with
         ``[terraform.(masters|workers).<name>].az`` set
    """

    new_config = deepcopy(new_config)

    # Skip if Terrafrom state is empty
    try:
        tf_state_resources = tf_state["values"]["root_module"]["resources"]
    except KeyError:
        logging.warning("Terraform state contains no resources")
        return new_config

    tf_var_defaults = get_tf_var_defaults()

    # Retrieve the availability zone of each node from the Terraform state
    node_azs = {
        # node-name               : az-name
        resource["values"]["name"]: resource["values"]["availability_zone"]
        for resource in tf_state_resources
        if (
            resource["type"] == "openstack_compute_instance_v2"
            and resource["name"] in ["master", "worker"]
        )
    }

    cluster_name = config["terraform"].get(
        "cluster_name", tf_var_defaults["cluster_name"]
    )

    # Set each node's availability zone to match the one in the Terraform state
    for node_group, infix in [("masters", "master"), ("workers", "worker")]:
        for name, node_attrs \
                in new_config["terraform"].get(node_group, {}).items():
            full_name = f"{cluster_name}-{infix}-{name}"  # taken from tf module
            # NOTE: If the availability zone is null
            #       it must not be set in the config
            if (node_az := node_azs.get(full_name, None)) is not None:
                node_attrs["az"] = node_az
            else:
                node_attrs.pop("az", None)

    return new_config


def migrate_to_explicit_az_config(config: dict, tf_state: dict) -> dict:
    """Migrate a config to use explicit set availability zones

    In the given config, ensures every node has an availability zone set
     if it has one stored in the given Terraform state.
    Replaces ``[terraform].enable_az_management``
    with ``[terraform].spread_gateways_across_azs``.

    Args:
        config: A parsed YAOOK/k8s configuration
        tf_state: A YAOOK/k8s Terraform state in JSON format

    Returns:
        A migrated copy of the given ``config``
    """

    new_config = deepcopy(config)

    tf_var_defaults = get_tf_var_defaults()

    # Configure each node's availability zones based on Terraform state
    new_config = sync_node_azs_in_tf_and_config(new_config, tf_state)

    # Replace `[terraform].enable_az_management`
    # with `[terraform].spread_gateways_across_azs`
    if "enable_az_management" in new_config["terraform"]:
        new_config["terraform"]["spread_gateways_across_azs"] = \
            new_config["terraform"].pop(
                "enable_az_management", tf_var_defaults["enable_az_management"]
            )

    return new_config


def get_args() -> argparse.Namespace:
    """Parse command line arguments and return them"""

    parser = argparse.ArgumentParser(
        description="Output an existing YAOOK/k8s config in the new format",
    )
    parser.add_argument(
        'tf_state_file', type=argparse.FileType('r'),
        default=sys_stdin,
        help="The path to a JSON Terraform state file."
             " (If set to '-' the state is read from stdin)")
    parser.add_argument(
        'config_file', type=argparse.FileType('r'),
        help="The path to a YAOOK/k8s config file in the old format",
    )

    return parser.parse_args()


if __name__ == "__main__":
    # Get command line arguments
    args = get_args()

    # Get existing config
    try:
        config = toml.loads(args.config_file.read())
    # NOTE: `toml.decoder.TomlDecodeError` must be used here
    #       when the standard library is in use.
    except toml.exceptions.ParseError:
        logging.error("Failed to parse the given config file.")
        exit(1)
    finally:
        args.config_file.close()

    # Get Terraform state
    try:
        tf_state = json.loads(args.tf_state_file.read())
    except json.decoder.JSONDecodeError:
        logging.error("Failed to parse the given JSON Terraform state file.")
        exit(1)
    finally:
        args.tf_state_file.close()

    # Convert config to new format
    new_config = convert_config_into_new_format(config)

    # Migrate config to explicit availability zone setting
    new_config = migrate_to_explicit_az_config(new_config, tf_state)

    # Print new config
    print(
        toml.dumps(new_config)
    )

    exit(0)
