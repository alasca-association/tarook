#!/usr/bin/env python3

"""
This tools assembles the relevant Yaml code for a specific Rook Ceph storage node to be
included in the CephCluster manifest. The code describes which disks to be used for
Ceph OSDs and which storage device is assigned to which OSD as metadata device.

This tool needs to be executed on each storage node which is supposed to be included in
the Rook Ceph cluster. The output Yaml code when needs to be copied into the
CephCluster manifest under the relevant section (`spec.storage.nodes[]`).

What this tool further does:
* Enumerates all /dev/sdX devices for usage as Ceph OSDs
* Two disks of the same size are expected to be the system disks (RAID 1) and thus are
    not used for Ceph OSDs
* In the generated manifest code OSDs will be addressed by their WWN
* Enumerates all /dev/nvmeXnY devices for usage as metadata devices for the Ceph OSDs
* Sanity checks, e.g. warns, if a disk has partitions

The -n options allows to specify another number of disks to be used as metadata devices
than discovered. This is helpful to spare some metadata devices for future use if more
OSD disks are added.
"""

import argparse
import subprocess
import re
import yaml
import os

# Set to true to get debug output
DEBUG = False


def debug_print(*msg):
    """
    Prints out a message if DEBUG is True
    """
    if DEBUG:
        print(msg)


def check_ge_zero(value):
    """
    Used by argparser to validate integers >= zero
    """
    ivalue = int(value)
    if ivalue < 0:
        raise argparse.ArgumentTypeError(
            "The specified number must be greater or equal to zero")
    return ivalue


# Parse command line options
parser = argparse.ArgumentParser(
    description='This script is to be executed on a Ceph storage node. It assembles the'
    'node specific Yaml code to be used in the CephCluster manifest')

parser.add_argument('-n', dest='number_of_metadata_devices',
                    help='Number of metadata devices to be used for the Ceph OSDs',
                    type=check_ge_zero)

args = parser.parse_args()

"""
Get output of `lsblk -o +WWN`

Developer hint: For your convenience during development you can run `lsblk -o +WWN >
lsblk.example` on a storage node. Then copy the file `lsblk.example` over to your
developer system and alter the below call to `["cat", "./lsblk.example"]`.
"""
sp = subprocess.run(["lsblk", "-o", "+WWN"], capture_output=True)

# Developer variant
# sp = subprocess.run(["cat", "./lsblk.example"], capture_output=True)

# Find potential Ceph OSDs and metadata devices
osds = {}
metadata_devices = {}
metadata_devices_flat = []
disks = []

for line in sp.stdout.splitlines():
    line = line.decode()
    debug_print(">", line)

    m = re.match(
        r"^(sd[a-z]|nvme\d+n\d+)\s.+\s(\d+[\.,]?\d+[MGT]?)\s.+\s(0x[0-9a-f]{16})?",
        line)
    if m:
        debug_print("=>", m, m.groups())
        disks.append(m.group(1))
        # OSD
        if m.group(1).startswith('sd'):
            osd = {'name': m.group(1), 'wwn': m.group(3), 'has_partitions': False}

            if m.group(2) in osds:
                osds[m.group(2)].append(osd)
            else:
                osds[m.group(2)] = [osd]
        # Anything else must be a metadata device
        else:
            mdd = {'name': m.group(1), 'has_partitions': False}
            metadata_devices_flat.append(m.group(1))

            if m.group(2) in metadata_devices:
                metadata_devices[m.group(2)].append(mdd)
            else:
                metadata_devices[m.group(2)] = [mdd]

# Check for devices having partitions
disks_with_partitions = []
for line in sp.stdout.splitlines():
    line = line.decode()

    m = re.search(r"(" + r"|".join(disks) + r")p?\d+.+\spart", line)
    if m:
        disks_with_partitions.append(m.group(1))
        debug_print("Partition found:", m, m.groups())

debug_print('disks_with_partitions:', disks_with_partitions)

for osd_group in osds:
    for osd in osds[osd_group]:
        if osd['name'] in disks_with_partitions:
            osd['has_partitions'] = True

for mdd_group in metadata_devices:
    for mdd in metadata_devices[mdd_group]:
        if mdd['name'] in disks_with_partitions:
            mdd['has_partitions'] = True

debug_print("\nOSDs:", osds)
debug_print("\nMetadata devices:", metadata_devices)
debug_print()

# Print out summary of the discovered potential OSD and metadata disks
heading = "Summary of the analysis"

print(heading)
print("="*len(heading))

print("\nThe following potential OSD disks have been identified grouped by their size:")

osd_count = 0
mdd_count = 0
potential_system_raids = []

for osd_group in osds:
    hint = ""

    if len(osds[osd_group]) == 2:
        potential_system_raids.append(osd_group)
        hint = "- This group looks like the RAID 1 used as system disk and thus will be"
        "ignored"

    print(osd_group, hint)

    for osd in osds[osd_group]:
        hint = ""

        if osd_group not in potential_system_raids:
            osd_count = osd_count + 1
            if osd['has_partitions']:
                hint = " (Warning disk has partitions!)"

        print("  /dev/{} (WWN: {}){}".format(osd['name'], osd['wwn'], hint))

if len(osds) > 2:
    print("\nWARNING: 2 different groups of disks are expected (one for the system and"
          "another for Ceph OSDs) but found {}!".format(len(osds)))

print("\nThe following metadata devices have been identified grouped by their size:")

for mdd_group in metadata_devices:
    print(mdd_group)
    for mdd in metadata_devices[mdd_group]:
        mdd_count = mdd_count + 1
        hint = ""

        if mdd['has_partitions']:
            hint = " (Warning disk has partitions!)"

        print("  /dev/{}{}".format(mdd['name'], hint))

# Handle number of discovered metadata devices VS specified number by command line
# option
if args.number_of_metadata_devices is not None:
    if args.number_of_metadata_devices > mdd_count:
        print("WARNING: It has been specified that {} metadata devices should be used"
              "but only {} are available.".format(
                args.number_of_metadata_devices, mdd_count))
    else:
        mdd_count = args.number_of_metadata_devices

if mdd_count > 0:
    print("\n{} metadata device(s) will be used. {} OSD(s) will be assigned to each"
          "metadata device.".format(mdd_count, osd_count/mdd_count))
else:
    print("\nNo metadata devices will be used.")

# Print out the relevant part for the CephCluster manifest
heading = "This is the Yaml code to be included in the CephCluster manifest under "\
            "spec.storage.nodes[]:"

print('\n' + heading)
print("="*len(heading))

osd_nr = 0
yaml_data = {
    'spec': {
        'storage': {
            'nodes': [{
                'name': os.uname()[1],
                'config': {
                    'encryptedDevice': True
                },
                'devices': []
            }]
        }
    }
}

for osd_group in osds:
    if osd_group in potential_system_raids:
        continue

    for osd in osds[osd_group]:
        yaml_osd = {}
        yaml_osd['name'] = '/dev/disk/by-id/wwn-' + osd['wwn']
        yaml_osd['config'] = {}

        if mdd_count > 0:
            yaml_osd['config']['metadataDevice'] = metadata_devices_flat[osd_nr %
                                                                         mdd_count]

        yaml_osd['config']['encryptedDevice'] = True
        osd_nr = osd_nr + 1
        yaml_data['spec']['storage']['nodes'][0]['devices'].append(yaml_osd)

print(yaml.dump(yaml_data))
