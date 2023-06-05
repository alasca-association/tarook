#!/usr/bin/python3

# Tooling for simulating offline conditions in a mk8s cluster deployed
# atop an OpenStack cloud.
# This is only needed for development and testing of the offline capabilities.
# Currently, only apt repos will be offlined, but full offlining will be supported
# at some point.


import json
import os
import re
import subprocess
import sys

import yaml


def load_tf_state():
    tf_state = json.loads(
        run(["managed-k8s/actions/terraform.sh", "show", "-json"],
            check=True, stdout=subprocess.PIPE).stdout
    )

    resource_map = {}
    for resource in tf_state["values"]["root_module"]["resources"]:
        resource_map[resource["address"]] = resource
    return resource_map


def run(args, **kwargs):
    print("+", args)
    return subprocess.run(args, **kwargs)


resource_map = load_tf_state()

GATEWAY = resource_map[
    "openstack_networking_port_v2.gw_vip_port"]["values"]["all_fixed_ips"][0]
ROUTER_ID = resource_map[
    "openstack_networking_router_v2.cluster_router"]["values"]["id"]

action = sys.argv[1]

archives = [
    "az1.clouds.archive.ubuntu.com",
    "security.ubuntu.com",
    "apt.kubernetes.io"
]

# XXX: perhaps this must be done remote if they use geo IP based DNS,
# but I think it's rather the repositories that redirect you to
# mirrors.
ips = []
for archive in archives:
    # One would think this can be done better with +short,
    # but +short does not work for extraction for CNAME records
    # then you get the IP and the CNAMEs in the output.
    dig_output = run(["dig", archive],
                     check=True, stdout=subprocess.PIPE, encoding="us-ascii").stdout
    for line in dig_output.splitlines():
        if line.startswith(";"):
            continue
        if not line.strip():
            continue
        m = re.match(r"[\w.]+\s+\d+\s+IN\s+A\s+(.+)$", line.strip())
        if m:
            ips.append(m.group(1))


# update offline.yaml
with open("inventory/02_trampoline/group_vars/gateways/offline.yaml", "w") as f:
    yaml.dump({"mk8s_offline_ips": ["{}/32".format(ip) for ip in ips]}, f)

if action == "setup":
    route_config = ["--no-route"]
    for ip in ips:
        route_config += ["--route", f"destination={ip}/32,gateway={GATEWAY}"]
    run(["openstack", "router", "set"] + route_config + [ROUTER_ID])
    run(["ansible-playbook",
         "-i", "../../inventory/02_trampoline/hosts", "_offline_cluster.yaml"],
        cwd="managed-k8s/k8s-base",
        env=dict(os.environ, **{"ANSIBLE_CONFIG": "../ansible/ansible.cfg"}))

elif action == "teardown":
    run(["openstack", "router", "set", "--no-route", ROUTER_ID])
    run(["ansible-playbook",
         "-i", "../../inventory/02_trampoline/hosts", "_online_cluster.yaml"],
        cwd="managed-k8s/k8s-base",
        env=dict(os.environ, **{"ANSIBLE_CONFIG": "../ansible/ansible.cfg"}))
