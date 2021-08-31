#!/usr/bin/python3

import pathlib
import json

TFVARS_DIR = pathlib.Path("terraform")
TFVARS_FILE = TFVARS_DIR / "config.tfvars.json"


def deploy_terraform_config(terraform_config):
    TFVARS_DIR.mkdir(exist_ok=True)
    with open(TFVARS_FILE, "w") as fout:
        json.dump(terraform_config, fout)
