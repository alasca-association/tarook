#!/usr/bin/env python3

import argparse
import json
from string import Template

template = Template(
    """
Host $host
    HostName $ip
    User $user
    IdentityFile $key
    Port $port"""
)


def parse_instance_attributes(attributes):
    """
        Parse the instance dictionary and extract the host, ip, and user.
    """

    host = attributes["name"]
    ip = attributes["network"][0]["fixed_ip_v4"]
    if "ubuntu" in attributes["image_name"].lower():
        user = "ubuntu"
    elif "debian" in attributes["image_name"].lower():
        user = "debian"
    elif "centos" in attributes["image_name"].lower():
        user = "centos"
    else:
        raise ValueError(f"Image name {attributes['image_name']} unknown")

    return host, ip, user


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--json", help="Terraform state, usually .tfstate file"
    )
    parser.add_argument(
        "--key", help="Path to OpenSSH private key", default="~/.ssh/is_rsa"
    )
    parser.add_argument("--port", help="SSH port", default="22")

    args = parser.parse_args()
    with open(args.json) as f:
        inventory = json.load(f)

    for resource in inventory.get("resources", {}):

        if resource.get("type") == "openstack_compute_instance_v2":
            for instance in resource.get("instances", {}):
                host, ip, user = parse_instance_attributes(
                    instance.get("attributes", {})
                )
                print(
                    template.substitute(
                        host=host, ip=ip, user=user, key=args.key,
                        port=args.port
                    )
                )


if __name__ == "__main__":
    main()
