#!/usr/bin/env python3

import argparse
from copy import deepcopy
import logging

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


def get_args() -> argparse.Namespace:
    """Parse command line arguments and return them"""

    parser = argparse.ArgumentParser(
        description="Output an existing YAOOK/k8s config in the new format",
    )
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

    # Convert config to new format
    new_config = convert_config_into_new_format(config)

    # Print new config
    print(
        toml.dumps(new_config)
    )

    exit(0)
