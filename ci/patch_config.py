#!/usr/bin/env python3

"""
This script is used in the CI to update the cluster configuration.
It takes a JSON-dict as command line argument and patches (deep
merges) it into the cluster configuration file.
"""

import toml
import json
import sys
from mergedeep import merge, Strategy

CONFIG_FILE = "config/config.toml"

try:
    cluster_config = toml.load(CONFIG_FILE)
except Exception:
    print("Error loading cluster config from {:s}".format(
        CONFIG_FILE), file=sys.stderr)
    raise

try:
    patch_config = json.loads(sys.argv[1])
except Exception:
    print("Error parsing patch from argv. Please provide a valid JSON.",
          file=sys.stderr)
    raise

cluster_config_patched = merge(cluster_config, patch_config,
                               strategy=Strategy.REPLACE)
try:
    with open(CONFIG_FILE, "w") as config_file:
        toml.dump(cluster_config_patched, config_file)
except Exception:
    print("Error dumping patched config as TOML to {:s}".format(
        CONFIG_FILE), file=sys.stderr)
    raise
