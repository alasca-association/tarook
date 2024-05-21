#!/usr/bin/env python3

import json
import sys

RC_DISRUPTION = 47
RC_NO_DISRUPTION = 0


def test_for_deletion(change):
    if "delete" in change["change"]["actions"]:
        print("Deleting a resource")
        return True
    return False


def test_for_flavor_upgrade(change):
    if change["type"] == "openstack_compute_instance_v2":
        if "update" in change["change"]["actions"]:
            old_flavor_id = change["change"]["before"]["flavor_id"]
            new_flavor_id = change["change"]["after"]["flavor_id"]
            if new_flavor_id != old_flavor_id:
                print("Flavor of an instance will change")
                return True
    return False


def main():
    tests = [test_for_deletion, test_for_flavor_upgrade]
    plan = json.load(sys.stdin)
    for change in plan["resource_changes"]:
        if change["type"] == "local_file":
            continue
        for test in tests:
            if test(change):
                print("Disruptive change detected")
                sys.exit(RC_DISRUPTION)
    sys.exit(RC_NO_DISRUPTION)


if __name__ == '__main__':
    main()
