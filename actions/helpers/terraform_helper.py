#!/usr/bin/env python3

import pathlib
import json
import sys
from hcl2 import loads

TFVARS_DIR = pathlib.Path("terraform")
TFVARS_FILE = TFVARS_DIR / "config.tfvars.json"
TF_DEFAULTS_FILE = pathlib.Path("managed-k8s/terraform/00-variables.tf")


def get_current_config():
    if not TFVARS_FILE.exists():
        return {}
    with open(TFVARS_FILE, "r") as f:
        return json.load(f)


def check_for_changed_cluster_name(current_config, new_config):
    if not TFVARS_FILE.exists():
        # If config.tfvars.json does not exist yet we can safely assume that
        # the cluster does not exist.
        return
    cluster_name = current_config.get("cluster_name", "")
    candidate_cluster_name = new_config.get("cluster_name", "")
    if cluster_name != candidate_cluster_name:
        print("[FATAL] Will not update terraform config because there is a mismatch between the deployed and future cluster_name. This would cause death and destruction.", file=sys.stderr) # NOQA
        if cluster_name == "":
            print("[FATAL] `cluster_name` wasn't set before, so remove the field from the config.toml", file=sys.stderr) # NOQA
        else:
            print(f"[FATAL] Set `cluster_name` to {cluster_name}. Your suggested change was {candidate_cluster_name} and is unacceptable.", file=sys.stderr) # NOQA
        sys.exit(1)


def deploy_terraform_config(terraform_config):
    current_config = get_current_config()
    check_for_changed_cluster_name(current_config, terraform_config)
    TFVARS_DIR.mkdir(exist_ok=True)
    with open(TFVARS_FILE, "w") as fout:
        json.dump(terraform_config, fout, indent=2)


def get_default_value_in_tf_vars(key, file_path=TF_DEFAULTS_FILE):
    with open(file_path, 'r') as file:
        content = file.read()

    for var in loads(content)['variable']:
        if key in var:
            return var.get(key).get('default')

    raise KeyError("Variable {} not found in {}".format(key, file_path))
