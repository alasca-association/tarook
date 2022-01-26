#!/usr/bin/env python3

import argparse
import yaml

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", help="The manifest file to patch")
    parser.add_argument("-i", "--inplace", help="Modify the file in-place",
                        action="store_true")
    args = vars(parser.parse_args())

    with open(args['file']) as f:
        data = yaml.safe_load(f)

    volumeMount = {"mountPath": "/etc/kubernetes/cloud-config",
                   "name": "cloud-config",
                   "readOnly": True}
    volume = {"name": "cloud-config",
              "hostPath": {
                "path": "/etc/kubernetes/cloud-config",
                "type": "FileOrCreate"}}
    # check before applying
    if len([vm for vm in data["spec"]["containers"][0]["volumeMounts"]
            if vm["name"] == "cloud-config"]) == 0:
        data["spec"]["containers"][0]["volumeMounts"].append(volumeMount)
    if len([v for v in data["spec"]["volumes"]
            if v["name"] == "cloud-config"]) == 0:
        data["spec"]["volumes"].append(volume)
    serialized = yaml.dump(data, default_flow_style=False)
    if args["inplace"]:
        with open(args["file"], "w") as f:
            f.write(serialized)
    else:
        print(serialized)
