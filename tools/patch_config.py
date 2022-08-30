#!/usr/bin/env python3

"""
This script is used in the CI to update the cluster configuration.
It takes a JSON-dict as command line argument and patches (deep
merges) it into the cluster configuration file. It is also possible
to subtract the entries from the config by using the "--subtract" flag.
"""

import toml
import json
import sys
from mergedeep import merge, Strategy
import argparse

CONFIG_FILE = "config/config.toml"


def subtract(a, b):
    """ Remove the keys in b from a. """
    for k in b:
        if k in a:
            if isinstance(b[k], dict):
                subtract(a[k], b[k])
            else:
                del a[k]


def main(arguments):
    try:
        cluster_config = toml.load(CONFIG_FILE)
    except Exception:
        print("Error loading cluster config from {:s}".format(
            CONFIG_FILE), file=sys.stderr)
        raise

    patch_config = arguments.patch_config
    if arguments.subtract:
        subtract(cluster_config, patch_config)
        cluster_config_patched = cluster_config
    else:
        cluster_config_patched = merge(cluster_config, patch_config,
                                       strategy=Strategy.REPLACE)
    try:
        with open(CONFIG_FILE, "w") as config_file:
            toml.dump(cluster_config_patched, config_file)
    except Exception:
        print("Error dumping patched config as TOML to {:s}".format(
            CONFIG_FILE), file=sys.stderr)
        raise


if __name__ == '__main__':
    argpar = argparse.ArgumentParser(
        description=("Script which is used in the CI to update the cluster \
                      configuration. \
                      It takes a JSON-dict as command line argument and patches(deep \
                      merges) it into the cluster configuration file."
                     )
    )
    argpar.add_argument(
        '--subtract',
        action='store_true',
        help="If set, the passed dictionary will be removed from the config, \
              instead of merged"
    )
    argpar.add_argument(
        '--patch-config',
        type=json.loads,
        help="JSON to be patched into the existing config."
    )
    args = argpar.parse_args()

    sys.exit(main(args) or 0)
